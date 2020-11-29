module Marten
  module DB
    class ReverseRelation
      def initialize(@model : Model.class, @field_id : String)
      end

      def field
        @field ||= @model.get_field(@field_id)
      end

      def one_to_many?
        field.is_a?(Field::OneToMany)
      end

      def one_to_one?
        # TODO
        false
      end
    end
  end
end
