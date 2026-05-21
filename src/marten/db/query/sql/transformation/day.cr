module Marten
  module DB
    module Query
      module SQL
        module Transformation
          class Day < DateTimePart
            transformation_name "day"

            def allows? : Bool
              field.is_a?(Field::DateTime) || field.is_a?(Field::Date)
            end
          end
        end
      end
    end
  end
end
