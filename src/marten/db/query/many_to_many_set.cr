require "./set"

module Marten
  module DB
    module Query
      # Represents a query set resulting from a many-to-many relation.
      class ManyToManySet(M) < Set(M)
        @m2m_field : Field::Base? = nil
        @m2m_through_from_field : Field::Base? = nil
        @m2m_through_to_field : Field::Base? = nil

        def initialize(
          @instance : Marten::DB::Model,
          @field_id : String,
          @through_related_name : String,
          @through_model_from_field_id : String,
          @through_model_to_field_id : String,
          query : SQL::Query(M)? = nil
        )
          @query = if query.nil?
                     q = SQL::Query(M).new
                     q.add_query_node(
                       Node.new({"#{@through_related_name}__#{@through_model_from_field_id}" => @instance})
                     )
                     q
                   else
                     query.not_nil!
                   end
        end

        # Adds the given objects to the many-to-many relationship.
        #
        # If the objects specified in `objs` are already in the relationship, they will be skipped and not added again.
        def add(*objs : M)
          add(objs.to_a)
        end

        # :ditto:
        def add(objs : Enumerable(M) | Iterable(M))
          query.connection.transaction do
            # Identify which objects are already added to the many to many relationship and skip them.
            existing_object_ids = m2m_field.as(Field::ManyToMany).through._base_queryset
              .using(query.using)
              .filter(
                Query::Node.new(
                  {
                    m2m_through_from_field.id        => @instance.pk.as(Field::Any),
                    "#{m2m_through_to_field.id}__in" => objs.map(&.pk!.as(Field::Any)).to_a,
                  }
                )
              )
              .pluck([m2m_through_to_field.id]).flatten

            # Add each object that was not already in the relationship.
            # TODO: bulk insert those objects instead of insert them one by one.
            objs.each do |obj|
              next if existing_object_ids.includes?(obj.id)
              through_obj = m2m_field.as(Field::ManyToMany).through.new
              through_obj.set_field_value(m2m_through_from_field.id, @instance.pk)
              through_obj.set_field_value(m2m_through_to_field.id, obj.pk)
              through_obj.save!(using: query.using)
            end

            reset_result_cache
          end
        end

        # Clears the many-to-many relationship.
        def clear : Nil
          query.connection.transaction do
            deletion_qs = m2m_field.as(Field::ManyToMany).through._base_queryset
              .using(query.using)
              .filter(Query::Node.new({m2m_through_from_field.id => @instance.pk.as(Field::Any)}))

            if (query.predicate_node.try(&.children.size) || 1) > 1
              # If the m2m queryset was filtered we need to target the right objects for deletion.
              deletion_qs = deletion_qs
                .filter(Query::Node.new({"#{m2m_through_to_field.id}__in" => pluck(:pk).flatten}))
            end

            deletion_qs.delete

            reset_result_cache
          end
        end

        # Removes the given objects from the many-to-many relationship.
        def remove(*objs : M) : Nil
          remove(objs.to_a)
        end

        # :ditto:
        def remove(objs : Enumerable(M) | Iterable(M)) : Nil
          query.connection.transaction do
            m2m_field.as(Field::ManyToMany).through._base_queryset
              .using(query.using)
              .filter(
                Query::Node.new(
                  {
                    m2m_through_from_field.id        => @instance.pk.as(Field::Any),
                    "#{m2m_through_to_field.id}__in" => objs.map(&.pk!.as(Field::Any)).to_a,
                  }
                )
              )
              .delete

            reset_result_cache
          end
        end

        protected def clone(other_query = nil)
          ManyToManySet(M).new(
            instance: @instance,
            field_id: @field_id,
            through_related_name: @through_related_name,
            through_model_from_field_id: @through_model_from_field_id,
            through_model_to_field_id: @through_model_to_field_id,
            query: other_query.nil? ? @query.clone : other_query.not_nil!
          )
        end

        private def m2m_field
          @m2m_field ||= @instance.class.get_field(@field_id)
        end

        private def m2m_through_from_field
          @m2m_through_from_field ||= m2m_field.as(Field::ManyToMany)
            .through
            .get_local_relation_field(@through_model_from_field_id)
        end

        private def m2m_through_to_field
          @m2m_through_to_field ||= m2m_field.as(Field::ManyToMany)
            .through
            .get_local_relation_field(@through_model_to_field_id)
        end
      end
    end
  end
end
