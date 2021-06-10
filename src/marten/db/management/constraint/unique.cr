module Marten
  module DB
    module Management
      module Constraint
        class Unique
          getter name
          getter column_names

          def initialize(@name : String, @column_names : Array(String))
          end

          def clone
            self.class.new(@name.dup, @column_names.clone)
          end
        end
      end
    end
  end
end
