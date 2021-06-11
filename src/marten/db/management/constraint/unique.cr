module Marten
  module DB
    module Management
      module Constraint
        class Unique
          @name : String
          @column_names : Array(String)

          getter name
          getter column_names

          def initialize(name : String | Symbol, column_names : Array(String | Symbol))
            @name = name.to_s
            @column_names = column_names.map(&.to_s)
          end

          def clone
            self.class.new(@name.dup, @column_names.clone)
          end
        end
      end
    end
  end
end
