module Marten
  module DB
    module Management
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
            @index = true
          )
            @to_table = to_table.to_s
            @to_column = to_column.to_s
          end

          def clone
            self.class.new(@name, @to_table, @to_column, @primary_key, @null, @unique, @index)
          end

          def serialize_args : ::String
            args = [%{"#{name}"}, %{"#{type}"}]
            args << %{to_table: "#{to_table}"}
            args << %{to_column: "#{to_column}"}
            args << %{primary_key: #{@primary_key}} if primary_key?
            args << %{null: #{@null}} if null?
            args << %{unique: #{@unique}} if unique?
            args << %{index: #{@index}} if !index?
            args.join(", ")
          end
        end
      end
    end
  end
end
