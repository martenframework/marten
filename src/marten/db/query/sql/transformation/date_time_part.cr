require "./base"

module Marten
  module DB
    module Query
      module SQL
        module Transformation
          # Base for calendar date/time part extractions (`year`, `month`, `day`, …) whose filter RHS is an integer.
          abstract class DateTimePart < Base
            def bind_parameter_value(value : Field::Any) : ::DB::Any
              case v = value
              when Nil
                nil
              when Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64
                v.to_i64
              else
                raise Errors::UnmetQuerySetCondition.new(
                  "Unsupported value type '#{v.class}' for column lookup transformation " \
                  "'#{self.class.transformation_name}' (integer bind parameters expected)"
                )
              end
            end
          end
        end
      end
    end
  end
end
