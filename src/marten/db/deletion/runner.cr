module Marten
  module DB
    module Deletion
      class Runner
        def initialize(@connection : Connection::Base)
          @records_to_delete = {} of Model.class => Array(Model)
          @dependencies = {} of Model.class => Array(Model.class)
          @querysets_to_raw_delete = [] of Tuple(Model.class, Query::Node)
        end

        def add(obj : Model, source : Nil | Model.class = nil) : Nil
          register_records_for_deletion([obj], source)
        end

        def add(qset, source : Nil | Model.class = nil)
          register_records_for_deletion(qset, source)
        end

        def execute : Int64
          count = 0.to_i64

          reorder_records_to_delete_according_to_dependencies

          @connection.transaction do
            # Step 1: delete all the querysets that were identified as raw-deleteable.
            @querysets_to_raw_delete.each do |model_klass, node|
              count += model_klass._base_queryset.filter(node).delete(raw: true)
            end

            # Step 2: perform field updates (set null values when applicable).
            # TODO.

            # Step 3: delete all the records that were registered for deletion.
            @records_to_delete.each do |model_klass, records|
              node = records.reduce(Query::Node.new) { |acc, rec| acc | Query::Node.new(pk: rec.id) }
              count += model_klass._base_queryset.filter(node).delete(raw: true)
            end
          end

          count
        end

        private def query_node_for(objs, reverse_relation)
          node_filters = Query::Node::FilterHash.new
          node_filters["#{reverse_relation.field_id}__in"] = objs.map(&.pk!.as(Field::Any))
          Query::Node.new(
            Array(Query::Node).new,
            Query::SQL::PredicateConnector::AND,
            false,
            node_filters
          )
        end

        private def raw_deleteable?(model_klass)
          model_klass.reverse_relations.select { |r| r.one_to_many? || r.one_to_one? }.all? do |reverse_relation|
            reverse_relation.on_delete.do_nothing?
          end
        end

        private def register_records_for_deletion(records, source)
          model = records[0].class

          # Register the records for deletion by keeping track of the order in which records should be deleted if a
          # source model is specified.
          @records_to_delete[model] ||= [] of Model
          records.each { |r| @records_to_delete[model] << r }

          if !source.nil?
            @dependencies[source] ||= [] of Model.class
            @dependencies[source] << model
          end

          # Loop over each of the deleted records model's reverse relations in order to identify how these can be
          # deleted too if applicable.
          model.reverse_relations.each do |reverse_relation|
            next if reverse_relation.on_delete.do_nothing?

            if raw_deleteable?(reverse_relation.model)
              @querysets_to_raw_delete << {reverse_relation.model, query_node_for(records, reverse_relation)}
            elsif reverse_relation.on_delete.cascade?
              add(
                reverse_relation.model._base_queryset.filter(query_node_for(records, reverse_relation)),
                source: model
              )
            elsif reverse_relation.on_delete.protect?
              raise Errors::ProtectedRecord.new(
                "Cannot delete '#{model}' records because they are protected by the following relation: " \
                "'#{reverse_relation.model}.#{reverse_relation.field_id}'"
              )
            elsif reverse_relation.on_delete.set_null?
              # TODO: set null
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
