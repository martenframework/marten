module Marten
  module DB
    module Query
      module SQL
        module Transformation
          class Second < DateTimePart
            transformation_name "second"

            def allows? : Bool
              field.is_a?(Field::DateTime)
            end
          end
        end
      end
    end
  end
end
