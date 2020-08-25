module Marten
  module DB
    module Management
      module SchemaEditor
        class PostgreSQL < Base
          def create_table_statement(table_name : String, column_definitions : String) : String
            "CREATE TABLE #{table_name} (#{column_definitions})"
          end

          def delete_table_statement(table_name : String) : String
            "DROP TABLE #{table_name} CASCADE"
          end
        end
      end
    end
  end
end
