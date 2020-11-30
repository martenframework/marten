module Marten
  module DB
    class ReverseRelation
      def initialize(@model : Model.class, @field_id : String)
      end

      def field
        @field ||= @model.get_field(@field_id)
      end

      # Returns `true` if the reverse relation is associated with a one to many field.
      def one_to_many?
        field.is_a?(Field::OneToMany)
      end

      # Returns `true` if the reverse relation is associated with a one to one field.
      def one_to_one?
        field.is_a?(Field::OneToOne)
      end
    end
  end
end
