module Marten
  abstract class Schema
    module Field
      # Represents a decimal schema field.
      class Decimal < Base
        getter decimal_places
        getter max_digits

        def initialize(
          @id : ::String,
          @max_digits : ::Int32,
          @decimal_places : ::Int32,
          @required : ::Bool = true,
        )
          validate_digits!
        end

        def deserialize(value) : BigDecimal?
          return if empty_value?(value)

          case value
          when Nil
            value
          when BigDecimal
            value
          when ::String
            parse_decimal(value)
          when ::Float
            parse_decimal(value.to_s)
          when ::Int
            parse_decimal(value.to_s)
          when ::JSON::Any
            deserialize(value.raw)
          else
            raise_unexpected_field_value(value)
          end
        end

        def serialize(value) : ::Array(::String) | Nil | ::String
          value.try(&.to_s)
        end

        def validate(schema, value)
          return if !value.is_a?(BigDecimal)

          decimals = value.scale
          digits = digit_count(value)

          if decimals > decimal_places
            schema.errors.add(
              id,
              I18n.t("marten.schema.field.decimal.errors.max_decimal_places", decimal_places: decimal_places)
            )
          end

          if digits > max_digits
            schema.errors.add(
              id,
              I18n.t("marten.schema.field.decimal.errors.max_digits", max_digits: max_digits)
            )
          end

          whole_digits = digits - decimals
          max_whole_digits = max_digits - decimal_places
          if whole_digits > max_whole_digits
            schema.errors.add(
              id,
              I18n.t("marten.schema.field.decimal.errors.max_whole_digits", max_whole_digits: max_whole_digits)
            )
          end
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:max_digits].is_a?(NilLiteral) %}
            {% raise "Decimal fields must define a 'max_digits' property" %}
          {% end %}
          {% if kwargs.is_a?(NilLiteral) || kwargs[:decimal_places].is_a?(NilLiteral) %}
            {% raise "Decimal fields must define a 'decimal_places' property" %}
          {% end %}
        end

        private def digit_count(value : BigDecimal) : Int32
          digits = value.value.abs.to_s
          digits == "0" && value.scale == 0 ? 0 : digits.size
        end

        private def invalid_error_message(_schema)
          I18n.t("marten.schema.field.decimal.errors.invalid")
        end

        private def parse_decimal(value : ::String) : BigDecimal
          BigDecimal.new(value)
        rescue InvalidBigDecimalException
          raise ArgumentError.new("Invalid decimal value")
        end

        private def validate_digits!
          if max_digits < 1
            raise ArgumentError.new("max_digits must be a positive integer")
          end

          if decimal_places < 0
            raise ArgumentError.new("decimal_places must be greater than or equal to 0")
          end

          if decimal_places > max_digits
            raise ArgumentError.new("decimal_places must be less than or equal to max_digits")
          end
        end
      end
    end
  end
end
