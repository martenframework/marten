module Marten
  module DB
    module Migrations
      module SchemaEditor
        class PostgreSQL < Base
          def create_table_statement(table_name : String, column_definitions : String)
            "CREATE TABLE #{table_name} (#{column_definitions})"
          end
        end
      end
    end
  end
end
