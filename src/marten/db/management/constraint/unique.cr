module Marten
  module DB
    module Management
      module Constraint
        class Unique
          getter name
          getter column_names

          def initialize(@name : String, @column_names : Array(String))
          end
        end
      end
    end
  end
end
