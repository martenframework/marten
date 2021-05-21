module Marten
  module DB
    class ReverseRelation
      @field : Field::Base?

      # Returns the ID of the reverse relation.
      getter id

      # Returns the field ID that initiated the reverse relation.
      getter field_id

      # Returns the model class targetted by the reverse relation.
      getter model

      def initialize(@id : String?, @model : Model.class, @field_id : String)
      end

      # Returns the "on delete" strategy to consider for the considered reverse relation.
      def on_delete : Deletion::Strategy
        (
          field.as?(Field::ManyToOne).try(&.on_delete) ||
            field.as?(Field::OneToOne).try(&.on_delete)
        ).not_nil!
      end

      # Returns `true` if the reverse relation is associated with a many to one field.
      def many_to_one?
        field.is_a?(Field::ManyToOne)
      end

      # Returns `true` if the reverse relation is associated with a one to one field.
      def one_to_one?
        field.is_a?(Field::OneToOne)
      end

      private def field
        @field ||= model.get_field(@field_id)
      end
    end
  end
end
