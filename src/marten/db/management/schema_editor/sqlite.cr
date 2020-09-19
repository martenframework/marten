module Marten
  module DB
    module Management
      module SchemaEditor
        class SQLite < Base
          def create_index_statement(name : String, table_name : String, columns : Array(String)) : String
            "CREATE INDEX #{name} ON #{table_name} (#{columns.join(", ")})"
          end

          def create_table_statement(table_name : String, column_definitions : String) : String
            "CREATE TABLE #{table_name} (#{column_definitions})"
          end

          def ddl_rollbackable? : Bool
            true
          end

          def delete_table_statement(table_name : String) : String
            "DROP TABLE #{table_name}"
          end
        end
      end
    end
  end
end
