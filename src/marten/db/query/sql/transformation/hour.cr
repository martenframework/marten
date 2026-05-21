module Marten
  module DB
    module Query
      module SQL
        module Transformation
          class Hour < DateTimePart
            transformation_name "hour"

            def allows? : Bool
              field.is_a?(Field::DateTime)
            end
          end
        end
      end
    end
  end
end
