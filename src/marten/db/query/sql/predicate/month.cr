require "./time_part"

module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class Month < TimePart
            predicate_name "month"

            protected def extract_time_part(value : Time) : Int64
              value.month.to_i64
            end

            protected def validate_coerced_value(value : Int64)
              return if value.in?(1_i64..12_i64)

              raise Errors::UnmetQuerySetCondition.new("'month' expects an integer between 1 and 12")
            end
          end
        end
      end
    end
  end
end
