module Marten
  module DB
    abstract class Migration
      module Column
        class ForeignKey < Base
          include IsBuiltInColumn

          @to_table : ::String
          @to_column : ::String

          getter to_column
          getter to_table

          def initialize(
            @name : ::String,
            to_table : ::String | Symbol,
            to_column : ::String | Symbol,
            @primary_key = false,
            @null = false,
            @unique = false,
            @index = false
          )
            @to_table = to_table.to_s
            @to_column = to_column.to_s
          end
        end
      end
    end
  end
end
