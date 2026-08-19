module Marten
  module DB
    module Deletion
      class Runner
        def initialize(@connection : Connection::Base)
          @records_to_delete = {} of Model.class => Array(Model)
          @dependencies = {} of Model.class => Array(Model.class)
          @field_updates = {} of Model.class => Array(Tuple(Hash(String, Field::Any), Query::Node))
          @querysets_to_raw_delete = [] of Tuple(Model.class, Query::Node)
        end

        def add(
          obj : Model,
          source : Nil | Model.class = nil,
          process_parent_models = true,
        ) : Nil
          register_records_for_deletion(
            [obj],
            source,
            process_parent_models,
          )
        end

        def add(
          qset,
          source : Nil | Model.class = nil,
          process_parent_models = true,
        )
          register_records_for_deletion(
            qset,
            source,
            process_parent_models,
          )
        end

        def execute : Int64
          count = 0.to_i64

          reorder_records_to_delete_according_to_dependencies

          @connection.transaction do
            # Step 1: delete all the querysets that were identified as raw-deletable.
            @querysets_to_raw_delete.each do |model_klass, node|
              count += model_klass._base_queryset.using(@connection.alias).filter(node).delete(raw: true)
            end

            # Step 2: perform field updates (set null values when applicable).
            @field_updates.each do |model_klass, updates|
              updates.each do |values, node|
                model_klass._base_queryset.using(@connection.alias).filter(node).update(values)
              end
            end

            # Step 3: delete all the records that were registered for deletion.
            @records_to_delete.each do |model_klass, records|
              node = records.reduce(Query::Node.new) { |acc, rec| acc | Query::Node.new(pk: rec.pk) }
              count += model_klass._base_queryset.using(@connection.alias).filter(node).delete(raw: true)
            end
          end

          count
        end

        private def field_update_values_for(reverse_relation)
          values = {} of String => Field::Any

          if reverse_relation.polymorphic?
            poly_field = reverse_relation.model.get_local_field(reverse_relation.field_id).as(Field::Polymorphic)
            values[poly_field.id_field_id] = nil
            values[poly_field.type_field_id] = nil
          else
            values[reverse_relation.field_id] = nil
          end

          values
        end

        private def query_node_for(objs, reverse_relation)
          pks = objs.map(&.pk!.as(Field::Any))

          if reverse_relation.polymorphic?
            poly_field = reverse_relation.model.get_local_field(reverse_relation.field_id).as(Field::Polymorphic)
            Query::Node.new(
              {
                "#{poly_field.id_field_id}__in" => pks,
                poly_field.type_field_id        => objs[0].class.name,
              }
            )
          else
            Query::Node.new({"#{reverse_relation.field_id}__in" => pks})
          end
        end

        private def raw_deletable?(model_klass)
          model_klass.local_reverse_relations.select do |r|
            r.many_to_one? || r.one_to_one? || r.polymorphic?
          end.all? do |reverse_relation|
            reverse_relation.on_delete.do_nothing?
          end
        end

        private def register_records_for_deletion(
          records,
          source,
          process_parent_models = true,
        )
          return if records.empty?

          model = records[0].class

          # Register the records for deletion by keeping track of the order in which records should be deleted if a
          # source model is specified.
          @records_to_delete[model] ||= [] of Model
          records.each { |r| @records_to_delete[model] << r }

          if !source.nil?
            @dependencies[source] ||= [] of Model.class
            @dependencies[source] << model
          end

          # Add the model's parents to the list of records to delete first.
          if process_parent_models
            model.parent_fields.each do |parent_field|
              # Ensure that the current model is a dependency of the parent models. This means that parent records
              # should be deleted before any child records.
              @dependencies[parent_field.related_model] ||= [] of Model.class
              @dependencies[parent_field.related_model] << model

              add(
                records.compact_map { |r| r.get_related_object(parent_field.as(Field::OneToOne).relation_name) },
                process_parent_models: false,
              )
            end
          end

          # Loop over each of the deleted records model's reverse relations in order to identify how these can be
          # deleted too if applicable.
          model.local_reverse_relations.each do |reverse_relation|
            next if reverse_relation.many_to_many?
            next if reverse_relation.on_delete.do_nothing?

            related_query_node = query_node_for(records, reverse_relation)
            related_records = reverse_relation.model._base_queryset.using(@connection.alias)
              .filter(related_query_node)

            if reverse_relation.on_delete.cascade? && raw_deletable?(reverse_relation.model)
              @querysets_to_raw_delete << {reverse_relation.model, related_query_node}
            elsif reverse_relation.on_delete.cascade?
              add(related_records, source: model, process_parent_models: !reverse_relation.parent_link?)
            elsif reverse_relation.on_delete.protect? && related_records.exists?
              raise Errors::ProtectedRecord.new(
                "Cannot delete '#{model}' records because they are protected by the following relation: " \
                "'#{reverse_relation.model}.#{reverse_relation.field_id}'"
              )
            elsif reverse_relation.on_delete.set_null?
              @field_updates[reverse_relation.model] ||= [] of Tuple(Hash(String, Field::Any), Query::Node)
              @field_updates[reverse_relation.model] << {
                field_update_values_for(reverse_relation),
                related_query_node,
              }
            end
          end
        end

        private def reorder_records_to_delete_according_to_dependencies
          ordered_models = [] of Model.class
          current_models = @records_to_delete.dup

          while ordered_models.size < current_models.size
            found = false

            current_models.keys.each do |model|
              next if ordered_models.includes?(model)
              dependencies = @dependencies[model]?

              # No dependencies or all the dependencies already in the ordered array of models means that the new model
              # can be added to the ordered array of models too.
              if dependencies.nil? || (dependencies.to_set - ordered_models.to_set).empty?
                ordered_models << model
                found = true
              end
            end

            return if !found
          end

          @records_to_delete = {} of Model.class => Array(Model)
          ordered_models.each { |m| @records_to_delete[m] = current_models[m] }
        end
      end
    end
  end
end
