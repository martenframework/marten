module Marten
  module DB
    abstract class Model
      module Table
        # Context for a specific table field.
        #
        # A field context is used to provide a mapping between a field and the model where the field originates from.
        class FieldContext
          getter field
          getter model

          def initialize(@field : Field::Base, @model : Model.class)
          end
        end
      end
    end
  end
end
