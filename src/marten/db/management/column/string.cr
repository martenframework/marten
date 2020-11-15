module Marten
  module DB
    module Management
      module Column
        class String < Base
          include IsBuiltInColumn

          def initialize(
            @name : ::String,
            @max_size : ::Int32,
            @primary_key = false,
            @null = false,
            @unique = false,
            @index = false
          )
          end

          def clone
            self.class.new(@name, @max_size, @primary_key, @null, @unique, @index)
          end

          private def db_type_parameters
            {max_size: @max_size}
          end
        end
      end
    end
  end
end
