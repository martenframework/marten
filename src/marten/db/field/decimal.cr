module Marten
  module DB
    module Field
      # A fixed-precision decimal model field.
      #
      # Decimal fields are persisted as `numeric(max_digits, decimal_places)` columns and are exposed as
      # `BigDecimal` objects in Crystal. Both `max_digits` and `decimal_places` are required:
      #
      # ```
      # class Product < Marten::Model
      #   field :id, :big_int, primary_key: true, auto: true
      #   field :price, :decimal, max_digits: 10, decimal_places: 2
      # end
      #
      # product = Product.new(price: 19.99)
      # product.price = 20
      # ```
      class Decimal < Base
        # :nodoc:
        alias AdditionalType = ::Float64 | ::Float32 | ::Int8 | ::Int16 | ::Int32 | ::Int64 | ::String

        getter decimal_places
        getter default
        getter max_digits

        def initialize(
          @id : ::String,
          @max_digits : ::Int32,
          @decimal_places : ::Int32,
          @primary_key = false,
          @default : BigDecimal? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil,
        )
          validate_digits!
        end

        def from_db(value) : BigDecimal?
          case value
          when Nil
            value.as?(Nil)
          when BigDecimal
            value.as?(BigDecimal)
          when ::String
            parse_decimal(value)
          when Float64, Float32, Int8, Int16, Int32, Int64
            parse_decimal(value.as(Float64 | Float32 | Int8 | Int16 | Int32 | Int64).to_s)
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : BigDecimal?
          from_db(result_set.read(BigDecimal | Nil))
        end

        def to_column : Management::Column::Base?
          Management::Column::Decimal.new(
            name: db_column!,
            max_digits: max_digits,
            decimal_places: decimal_places,
            primary_key: primary_key?,
            null: null?,
            unique: unique?,
            index: index?,
            default: to_db(default)
          )
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when BigDecimal
            format_decimal(value)
          when ::String
            format_decimal(parse_decimal(value))
          when Float64, Float32, Int8, Int16, Int32, Int64
            format_decimal(parse_decimal(value.as(Float64 | Float32 | Int8 | Int16 | Int32 | Int64).to_s))
          else
            raise_unexpected_field_value(value)
          end
        end

        def validate(record, value)
          return if value.nil?

          decimal = case value
                    when BigDecimal
                      value
                    when ::String, Float64, Float32, Int8, Int16, Int32, Int64
                      begin
                        from_db(value).not_nil!
                      rescue ArgumentError | InvalidBigDecimalException | Errors::UnexpectedFieldValue
                        record.errors.add(id, I18n.t("marten.db.field.decimal.errors.invalid"))
                        return
                      end
                    else
                      return
                    end

          decimals = decimal.scale
          digits = digit_count(decimal)

          if decimals > decimal_places
            record.errors.add(
              id,
              I18n.t("marten.db.field.decimal.errors.max_decimal_places", decimal_places: decimal_places)
            )
          end

          if digits > max_digits
            record.errors.add(
              id,
              I18n.t("marten.db.field.decimal.errors.max_digits", max_digits: max_digits)
            )
          end

          whole_digits = digits - decimals
          max_whole_digits = max_digits - decimal_places
          if whole_digits > max_whole_digits
            record.errors.add(
              id,
              I18n.t("marten.db.field.decimal.errors.max_whole_digits", max_whole_digits: max_whole_digits)
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

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          class ::{{ model_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
              )
            )

            {% if !model_klass.resolve.abstract? %}
              @[Marten::DB::Model::Table::FieldInstanceVariable(
                field_klass: {{ @type }},
                field_kwargs: {% unless kwargs.is_a?(NilLiteral) %}{{ kwargs }}{% else %}nil{% end %},
                field_type: {{ field_ann[:exposed_type] }} | {{ field_ann[:additional_type] }},
                model_klass: {{ model_klass }}
              )]

              @{{ field_id }} : BigDecimal?

              def {{ field_id }} : BigDecimal?
                @{{ field_id }}
              end

              def {{ field_id }}!
                @{{ field_id }}.not_nil!
              end

              def {{ field_id }}?
                self.class.get_field({{ field_id.stringify }}).getter_value?({{ field_id }})
              end

              def {{ field_id }}=(
                value : BigDecimal | Float64 | Float32 | Int8 | Int16 | Int32 | Int64 | ::String | Nil
              )
                @{{ field_id }} = case value
                                  when Nil
                                    nil
                                  when BigDecimal
                                    value
                                  when ::String
                                    BigDecimal.new(value)
                                  else
                                    BigDecimal.new(value.to_s)
                                  end
              end
            {% end %}
          end
        end

        private def digit_count(value : BigDecimal) : Int32
          digits = value.value.abs.to_s
          digits == "0" && value.scale == 0 ? 0 : digits.size
        end

        private def format_decimal(value : BigDecimal) : ::String
          # Persist using a plain decimal string so all DB backends bind the value as text
          # without losing precision (DB::Any does not include BigDecimal).
          value.to_s
        end

        private def parse_decimal(value : ::String) : BigDecimal
          BigDecimal.new(value)
        rescue InvalidBigDecimalException
          raise_unexpected_field_value(value)
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
