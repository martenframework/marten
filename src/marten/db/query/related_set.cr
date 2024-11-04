require "./set"

module Marten
  module DB
    module Query
      # Represents a query set resulting from a many-to-one relation.
      class RelatedSet(M) < Set(M)
        def initialize(
          @instance : Marten::DB::Model,
          @related_field_id : String,
          query : SQL::Query(M)? = nil,
          @assign_related : Bool = false
        )
          @query = if query.nil?
                     q = SQL::Query(M).new
                     q.add_query_node(Node.new({@related_field_id => @instance.pk}))
                     q
                   else
                     query.not_nil!
                   end
        end

        protected def fetch
          super
          @result_cache.not_nil!.each { |r| r.assign_related_object(@instance, @related_field_id) } if @assign_related
        end

        protected def build_record(**kwargs)
          record = M.new(**kwargs)
          record.assign_related_object(@instance, @related_field_id)
          record
        end

        protected def clone(other_query = nil)
          RelatedSet(M).new(
            instance: @instance,
            related_field_id: @related_field_id,
            query: other_query.nil? ? @query.clone : other_query.not_nil!,
            assign_related: @assign_related
          )
        end
      end
    end
  end
end
