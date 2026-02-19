module Marten
  module DB
    module Query
      module SQL
        module Predicate
          abstract class TimePart < Base
            def initialize(
              left_operand : Annotation::Base | Field::Base,
              right_operand : Field::Any | Array(Field::Any),
              alias_prefix : String,
              @comparison_predicate : String = "exact",
            )
              super(left_operand, right_operand, alias_prefix)
            end

            def to_sql(connection : Connection::Base)
              validate_comparison_predicate!
              validate_left_operand!

              case @comparison_predicate
              when "in"
                to_sql_for_in(connection)
              when "isnull"
                to_sql_for_isnull(connection)
              else
                to_sql_for_scalar_comparison(connection)
              end
            end

            protected def allowed_field?(field : Field::Base) : Bool
              field.is_a?(Field::Date) || field.is_a?(Field::DateTime)
            end

            protected def field_compatibility_error_message : String
              "'#{self.class.predicate_name}' can only be used with date or date_time fields"
            end

            protected def invalid_value_error_message : String
              "'#{self.class.predicate_name}' expects an integer, a numeric string, or a Time value"
            end

            protected def validate_coerced_value(_value : Int64)
            end

            protected abstract def extract_time_part(value : Time) : Int64

            private def coerce_value(value : Field::Any) : Int64
              case value
              when Int8, Int16, Int32, Int64
                value.to_i64
              when String
                value.to_i64? || raise_invalid_value_error
              when Time
                extract_time_part(value)
              else
                raise_invalid_value_error
              end
            end

            private def coerced_values_for_in_predicate : Array(Int64)
              if !right_operand.is_a?(Array(Field::Any))
                raise Errors::UnmetQuerySetCondition.new("In predicate requires an array of values")
              end

              values = right_operand.as(Array(Field::Any))
              raise Errors::EmptyResults.new if values.empty?

              values.map do |value|
                coerced_value = coerce_value(value)
                validate_coerced_value(coerced_value)
                coerced_value
              end
            end

            private def raise_invalid_value_error
              raise Errors::UnmetQuerySetCondition.new(invalid_value_error_message)
            end

            private def sql_left_operand(connection)
              field = left_operand.as(Field::Base)
              connection.left_operand_for(
                "#{alias_prefix}.#{field.db_column}",
                self.class.predicate_name
              )
            end

            private def validate_comparison_predicate!
              return if Predicate.time_part_comparison_predicate?(@comparison_predicate)

              raise Errors::InvalidField.new(
                "Unsupported chained predicate type '#{@comparison_predicate}' for '#{self.class.predicate_name}'"
              )
            end

            private def validate_left_operand!
              if left_operand.is_a?(Annotation::Base)
                raise Errors::InvalidField.new(
                  "'#{self.class.predicate_name}' cannot be used with annotation values"
                )
              end

              field = left_operand.as(Field::Base)
              return if allowed_field?(field)

              raise Errors::InvalidField.new(field_compatibility_error_message)
            end

            private def to_sql_for_in(connection : Connection::Base)
              coerced_values = coerced_values_for_in_predicate

              placeholders = String.build do |s|
                s << "IN ( "
                s << coerced_values.join(" , ") { "%s" }
                s << " )"
              end

              sql_values = [] of ::DB::Any
              coerced_values.each { |value| sql_values << value }

              {"#{sql_left_operand(connection)} #{placeholders}", sql_values}
            end

            private def to_sql_for_isnull(connection : Connection::Base)
              unless right_operand.is_a?(Bool)
                raise Errors::UnmetQuerySetCondition.new("'#{self.class.predicate_name}__isnull' expects a boolean")
              end

              sql = right_operand.as(Bool) ? "IS NULL" : "IS NOT NULL"
              {"#{sql_left_operand(connection)} #{sql}", [] of ::DB::Any}
            end

            private def to_sql_for_scalar_comparison(connection : Connection::Base)
              if right_operand.is_a?(Array(Field::Any))
                raise_invalid_value_error
              end

              coerced_value = coerce_value(right_operand.as(Field::Any))
              validate_coerced_value(coerced_value)

              operator = connection.operator_for(@comparison_predicate) % "%s"
              {"#{sql_left_operand(connection)} #{operator}", [coerced_value] of ::DB::Any}
            end
          end
        end
      end
    end
  end
end
