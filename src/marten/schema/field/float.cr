module Marten
  abstract class Schema
    module Field
      # Represents a float schema field.
      class Float < Base
        # Returns the maximum value allowed.
        getter max_value

        # Returns the minimum value allowed.
        getter min_value

        def initialize(
          @id : ::String,
          @required : ::Bool = true,
          @min_value : Float64? = nil,
          @max_value : Float64? = nil
        )
        end

        def deserialize(value) : Float64?
          return if empty_value?(value)

          case value
          when Nil
            value
          when ::String
            Float64.new(value)
          when ::Float
            value.to_f64
          when ::Int
            value.to_f64
          when ::JSON::Any
            deserialize(value.raw)
          else
            raise_unexpected_field_value(value)
          end
        end

        def serialize(value) : ::String?
          value.try(&.to_s)
        end

        def validate(schema, value)
          return if !value.is_a?(Float64)

          if !value.finite?
            schema.errors.add(id, invalid_error_message(schema), type: :invalid)
            return
          end

          if !min_value.nil? && value < min_value.not_nil!
            schema.errors.add(id, I18n.t("marten.schema.field.float.errors.too_small", min_value: min_value))
          end

          if !max_value.nil? && value > max_value.not_nil!
            schema.errors.add(id, I18n.t("marten.schema.field.float.errors.too_big", max_value: max_value))
          end
        end

        private def invalid_error_message(_schema)
          I18n.t("marten.schema.field.float.errors.invalid")
        end
      end
    end
  end
end
