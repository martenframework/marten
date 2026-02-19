require "./time_part"

module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class Day < TimePart
            predicate_name "day"

            protected def extract_time_part(value : Time) : Int64
              value.day.to_i64
            end

            protected def validate_coerced_value(value : Int64)
              return if value.in?(1_i64..31_i64)

              raise Errors::UnmetQuerySetCondition.new("'day' expects an integer between 1 and 31")
            end
          end
        end
      end
    end
  end
end
