require "./set"

module Marten
  module DB
    module Query
      class ManyToManySet(Model) < Set(Model)
        @m2m_field : Field::Base? = nil
        @m2m_through_from_field : Field::Base? = nil
        @m2m_through_to_field : Field::Base? = nil

        def initialize(
          @instance : Marten::DB::Model,
          @field_id : String,
          @through_related_name : String,
          @through_model_from_field_id : String,
          @through_model_to_field_id : String,
          query : SQL::Query(Model)? = nil
        )
          @query = if query.nil?
                     q = SQL::Query(Model).new
                     q.add_query_node(
                       Node.new({"#{@through_related_name}__#{@through_model_from_field_id}" => @instance})
                     )
                     q
                   else
                     query.not_nil!
                   end
        end

        def add(*objs : Model)
          query.connection.transaction do
            # Identify which objects are already added to the many to many relationship and skip them.
            # TODO: leverage the ability to only retrieve specific column values from the DB.
            existing_obj_ids = m2m_field.as(Field::ManyToMany).through._base_queryset.filter(
              Query::Node.new(
                {
                  m2m_through_from_field.id        => @instance.pk.as(Field::Any),
                  "#{m2m_through_to_field.id}__in" => objs.map(&.pk!.as(Field::Any)).to_a,
                }
              )
            ).map { |o| o.get_field_value(m2m_through_to_field.id).as(Field::Any) }

            # Add each object that was not already in the relationship.
            # TODO: bulk insert those objects instead of insert them one by one.
            objs.each do |obj|
              next if existing_obj_ids.includes?(obj.id)
              through_obj = m2m_field.as(Field::ManyToMany).through.new
              through_obj.set_field_value(m2m_through_from_field.id, @instance.pk)
              through_obj.set_field_value(m2m_through_to_field.id, obj.pk)
              through_obj.save!
            end
          end
        end

        protected def clone
          cloned = self.class.new(
            @instance,
            @field_id,
            @through_related_name,
            @through_model_from_field_id,
            @through_model_to_field_id,
            @query.clone
          )
          cloned
        end

        private def m2m_field
          @m2m_field ||= @instance.class.get_field(@field_id)
        end

        private def m2m_through_from_field
          @m2m_through_from_field ||= m2m_field.as(Field::ManyToMany)
            .through
            .get_relation_field(@through_model_from_field_id)
        end

        private def m2m_through_to_field
          @m2m_through_to_field ||= m2m_field.as(Field::ManyToMany)
            .through
            .get_relation_field(@through_model_to_field_id)
        end
      end
    end
  end
end
