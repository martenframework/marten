module Marten
  module DB
    module Management
      class Statement
        class Columns < Reference
          getter table
          getter columns

          def initialize(@quote_proc : Proc(String, String), @table : String, @columns : Array(String))
          end

          def references_column?(table : String, column : String?)
            @table == table && @columns.any? { |c| c == column }
          end

          def references_table?(name : String?)
            @table == name
          end

          def rename_column(table : String, old_name : String, new_name : String)
            return if @table != table
            return if (pos = @columns.index(old_name)).nil?
            @columns[pos] = new_name
          end

          def rename_table(old_name : String, new_name : String)
            @table = new_name if @table == old_name
          end

          def to_s
            @columns.join(", ") { |c| @quote_proc.call(c) }
          end
        end
      end
    end
  end
end
