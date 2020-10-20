module Marten
  module DB
    abstract class Migration
      module Column
        class ForeignKey < Base
          include IsBuiltInColumn

          getter to_column
          getter to_table

          def initialize(
            @name : ::String,
            @to_table : ::String,
            @to_column : ::String,
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
