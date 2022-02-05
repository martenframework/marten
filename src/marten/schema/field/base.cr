module Marten
  abstract class Schema
    module Field
      # Abstract base schema field implementation.
      abstract class Base
        # Returns the ID of the field used in the associated schema.
        getter id

        def initialize(
          @id : ::String,
          @required : ::Bool = true
        )
        end

        # Deserializes a raw field value to the corresponding field value.
        abstract def deserialize(value)

        # Serializes a field value.
        abstract def serialize(value) : ::String?

        # :nodoc:
        def perform_validation(schema : Schema)
          begin
            value = deserialize(schema.get_field_value(id))
          rescue ArgumentError
            schema.errors.add(id, invalid_error_message(schema), type: :invalid)
            return
          end

          if empty_value?(value) && required?
            schema.errors.add(id, required_error_message(schema), type: :required)
          end

          validate(schema, value)

          value
        end

        # Returns a boolean indicating whether the field is required.
        def required?
          @required
        end

        # Runs custom validation logic for a specific schema field and schema object.
        #
        # This method should be overriden for each field implementation that requires custom validation logic.
        def validate(schema, value)
        end

        private EMPTY_VALUES = [nil, ""]

        private def empty_value?(value) : ::Bool
          EMPTY_VALUES.includes?(value)
        end

        private def invalid_error_message(_schema)
          I18n.t("marten.schema.field.base.errors.invalid")
        end

        private def raise_unexpected_field_value(value)
          raise Errors::UnexpectedFieldValue.new("Unexpected value received for field '#{id}': #{value}")
        end

        private def required_error_message(_schema)
          I18n.t("marten.schema.field.base.errors.required")
        end
      end
    end
  end
end
