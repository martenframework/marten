require "./time_part"

module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class Minute < TimePart
            predicate_name "minute"

            protected def allowed_field?(field : Field::Base) : Bool
              field.is_a?(Field::DateTime)
            end

            protected def extract_time_part(value : Time) : Int64
              value.minute.to_i64
            end

            protected def field_compatibility_error_message : String
              "'minute' can only be used with date_time fields"
            end

            protected def validate_coerced_value(value : Int64)
              return if value.in?(0_i64..59_i64)

              raise Errors::UnmetQuerySetCondition.new("'minute' expects an integer between 0 and 59")
            end
          end
        end
      end
    end
  end
end
