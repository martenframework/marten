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

        # Returns `true` if the value is considered empty by the field.
        def empty_value?(value) : ::Bool
          EMPTY_VALUES.includes?(value.is_a?(::JSON::Any) ? value.raw : value)
        end

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

        # :nodoc:
        macro check_definition(field_id, kwargs)
        end

        # :nodoc:
        macro contribute_to_schema(schema_klass, field_id, field_ann, kwargs)
          # Registers the field to the schema class.

          class ::{{ schema_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
              )
            )

            def {{ field_id }} : {{ field_ann[:exposed_type] }}?
              validated_data[{{ field_id.stringify }}]?.as({{ field_ann[:exposed_type] }}?)
            end

            def {{ field_id }}!
              {{ field_id }}.not_nil!
            end

            def {{ field_id }}?
              !self.class.get_field({{ field_id.stringify }}).empty_value?({{ field_id }})
            end
          end
        end

        private EMPTY_VALUES = [nil, ""]

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
