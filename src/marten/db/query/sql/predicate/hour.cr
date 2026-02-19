require "./time_part"

module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class Hour < TimePart
            predicate_name "hour"

            protected def allowed_field?(field : Field::Base) : Bool
              field.is_a?(Field::DateTime)
            end

            protected def extract_time_part(value : Time) : Int64
              value.hour.to_i64
            end

            protected def field_compatibility_error_message : String
              "'hour' can only be used with date_time fields"
            end

            protected def validate_coerced_value(value : Int64)
              return if value.in?(0_i64..23_i64)

              raise Errors::UnmetQuerySetCondition.new("'hour' expects an integer between 0 and 23")
            end
          end
        end
      end
    end
  end
end
