module Marten
  module DB
    module Management
      module Column
        class Text < Base
          include IsBuiltInColumn

          def clone
            self.class.new(@name, @primary_key, @null, @unique, @index, @default)
          end
        end
      end
    end
  end
end
