require "./set"

module Marten
  module DB
    module Query
      # Represents a query set resulting from a many-to-one or one-to-one relation.
      class RelatedSet(Model) < Set(Model)
        def initialize(@instance : Marten::DB::Model, @related_field_id : String, query : SQL::Query(Model)? = nil)
          @query = if query.nil?
                     q = SQL::Query(Model).new
                     q.add_query_node(Node.new({@related_field_id => @instance.pk}))
                     q
                   else
                     query.not_nil!
                   end
        end

        protected def clone(other_query = nil)
          RelatedSet(Model).new(
            instance: @instance,
            related_field_id: @related_field_id,
            query: other_query.nil? ? @query.clone : other_query.not_nil!
          )
        end
      end
    end
  end
end
