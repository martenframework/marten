module Marten
  module DB
    module Query
      module SQL
        module Transformation
          class Minute < DateTimePart
            transformation_name "minute"

            def allows? : Bool
              field.is_a?(Field::DateTime)
            end
          end
        end
      end
    end
  end
end
