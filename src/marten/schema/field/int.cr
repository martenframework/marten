module Marten
  abstract class Schema
    module Field
      # Represents an integer schema field.
      class Int < Base
        # Returns the maximum value allowed.
        getter max_value

        # Returns the minimum value allowed.
        getter min_value

        def initialize(
          @id : ::String,
          @required : ::Bool = true,
          @min_value : Int32 | Int64 | Nil = nil,
          @max_value : Int32 | Int64 | Nil = nil
        )
        end

        def deserialize(value) : Int64?
          return if empty_value?(value)

          case value
          when Nil
            value
          when ::Int
            value.to_i64
          when ::String
            Int64.new(value)
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
          return if !value.is_a?(::Int)

          if !min_value.nil? && value < min_value.not_nil!
            schema.errors.add(id, I18n.t("marten.schema.field.int.errors.too_small", min_value: min_value))
          end

          if !max_value.nil? && value > max_value.not_nil!
            schema.errors.add(id, I18n.t("marten.schema.field.int.errors.too_big", max_value: max_value))
          end
        end

        private def invalid_error_message(_schema)
          I18n.t("marten.schema.field.int.errors.invalid")
        end
      end
    end
  end
end
