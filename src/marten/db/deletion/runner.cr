module Marten
  module DB
    module Deletion
      class Runner
        def initialize(@connection : Connection::Base)
          @records_to_delete = {} of Model.class => Array(Model)
          @dependencies = {} of Model.class => Array(Model.class)
          @field_updates = {} of Model.class => Hash(Tuple(String, Field::Any), Query::Node)
          @querysets_to_raw_delete = [] of Tuple(Model.class, Query::Node)
        end

        def add(obj : Model, source : Nil | Model.class = nil, reverse_relations = true) : Nil
          register_records_for_deletion([obj], source, reverse_relations: reverse_relations)
        end

        def add(qset, source : Nil | Model.class = nil, reverse_relations = true)
          register_records_for_deletion(qset, source, reverse_relations: reverse_relations)
        end

        def execute : Int64
          count = 0.to_i64

          reorder_records_to_delete_according_to_dependencies

          @connection.transaction do
            # Step 1: delete all the querysets that were identified as raw-deleteable.
            @querysets_to_raw_delete.each do |model_klass, node|
              count += model_klass._base_queryset.using(@connection.alias).filter(node).delete(raw: true)
            end

            # Step 2: perform field updates (set null values when applicable).
            @field_updates.each do |model_klass, query_node_updates|
              query_node_updates.each do |(field_id, value), node|
                model_klass._base_queryset.using(@connection.alias).filter(node).update({field_id => value})
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

        private def query_node_for(objs, reverse_relation)
          Query::Node.new(
            {"#{reverse_relation.field_id}__in" => objs.map(&.pk!.as(Field::Any))}
          )
        end

        private def raw_deleteable?(model_klass)
          model_klass.reverse_relations.select { |r| r.many_to_one? || r.one_to_one? }.all? do |reverse_relation|
            reverse_relation.on_delete.do_nothing?
          end
        end

        private def register_records_for_deletion(records, source, reverse_relations = true)
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
          model.parent_fields.each do |parent_field|
            # Ensure that the current model is a dependency of the parent models. This means that parent records should
            # be deleted before any child records.
            @dependencies[parent_field.related_model] ||= [] of Model.class
            @dependencies[parent_field.related_model] << model

            add(
              records.compact_map { |r| r.get_relation(parent_field.as(Field::OneToOne).relation_name) },
              reverse_relations: false
            )
          end

          return unless reverse_relations

          # Loop over each of the deleted records model's reverse relations in order to identify how these can be
          # deleted too if applicable.
          model.reverse_relations.each do |reverse_relation|
            next if reverse_relation.many_to_many?
            next if reverse_relation.parent_link?
            next if reverse_relation.on_delete.do_nothing?

            related_records = reverse_relation.model._base_queryset.using(@connection.alias)
              .filter(query_node_for(records, reverse_relation))

            if reverse_relation.on_delete.cascade? && raw_deleteable?(reverse_relation.model)
              @querysets_to_raw_delete << {reverse_relation.model, query_node_for(records, reverse_relation)}
            elsif reverse_relation.on_delete.cascade?
              add(related_records, source: model)
            elsif reverse_relation.on_delete.protect? && related_records.exists?
              raise Errors::ProtectedRecord.new(
                "Cannot delete '#{model}' records because they are protected by the following relation: " \
                "'#{reverse_relation.model}.#{reverse_relation.field_id}'"
              )
            elsif reverse_relation.on_delete.set_null?
              @field_updates[reverse_relation.model] ||= {} of Tuple(String, Field::Any) => Query::Node
              @field_updates[reverse_relation.model][{reverse_relation.field_id, nil}] = query_node_for(
                records,
                reverse_relation
              )
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
