module Marten
  module DB
    module Query
      module SQL
        module Transformation
          class Year < DateTimePart
            transformation_name "year"

            def allows? : Bool
              field.is_a?(Field::DateTime) || field.is_a?(Field::Date)
            end
          end
        end
      end
    end
  end
end
