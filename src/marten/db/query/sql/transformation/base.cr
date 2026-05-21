module Marten
  module DB
    module Query
      module SQL
        module Transformation
          abstract class Base
            class_getter transformation_name : String = ""

            def self.transformation_name(name : String?)
              @@transformation_name = name
            end

            getter field : Field::Base

            def initialize(@field : Field::Base)
            end

            abstract def allows? : Bool

            abstract def bind_parameter_value(value : Field::Any) : ::DB::Any

            def apply(connection : Connection::Base, column_reference : String) : String
              connection.left_operand_for_transformation(column_reference, self.class.transformation_name)
            end
          end
        end
      end
    end
  end
end
