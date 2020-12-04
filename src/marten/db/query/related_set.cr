require "./set"

module Marten
  module DB
    module Query
      class RelatedSet(Model) < Set(Model)
        def initialize(@instance : Marten::DB::Model, @related_field_id : String, @query = SQL::Query(Model).new)
        end

        protected def clone
          cloned = self.class.new(@instance, @related_field_id, @query.clone)
          cloned
        end

        protected def fetch
          node_filters = Node::FilterHash.new
          node_filters[@related_field_id] = @instance.pk
          @query.add_query_node(
            Node.new(
              Array(Node).new,
              SQL::PredicateConnector::AND,
              false,
              node_filters
            )
          )
          @result_cache = @query.execute
        end
      end
    end
  end
end
