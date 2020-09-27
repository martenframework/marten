module Marten
  module DB
    abstract class Migration
      module Column
        class ForeignKey < Base
          include IsBuiltInColumn

          def initialize(
            @name : ::String,
            @to_table_name : ::String,
            @primary_key = false,
            @null = false,
            @unique = false,
            @index = false
          )
          end
        end
      end
    end
  end
end
