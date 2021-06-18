module Marten
  module DB
    module Management
      class Statement
        class ForeignKeyName < Reference
          getter table
          getter column
          getter to_table
          getter to_column

          def initialize(
            @index_name_proc : Proc(String, Array(String), String, String),
            @table : String,
            @column : String,
            @to_table : String,
            @to_column : String
          )
          end

          def references_column?(table : String, column : String?)
            (@table == table && @column == column) || (@to_table == table && @to_column == column)
          end

          def references_table?(name : String?)
            @table == name || @to_table == name
          end

          def rename_column(table : String, old_name : String, new_name : String)
            if @table == table && @column == old_name
              @column = new_name
            elsif @to_table == table && @to_column == old_name
              @to_column = new_name
            end
          end

          def rename_table(old_name : String, new_name : String)
            @table = new_name if @table == old_name
            @to_table = new_name if @to_table == old_name
          end

          def to_s
            IndexName.new(@index_name_proc, @table, [@column], "_fk_#{@to_table}_#{@to_column}").to_s
          end
        end
      end
    end
  end
end
