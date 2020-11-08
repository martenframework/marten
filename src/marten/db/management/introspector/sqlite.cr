module Marten
  module DB
    module Management
      module Introspector
        class SQLite < Base
          def foreign_key_constraint_names(table_name : String, column_name : String) : Array(String)
            [] of String
          end

          def get_foreign_key_constraint_names_statement(table_name : String, column_name : String) : String
            raise NotImplementedError.new("SQLite foreign keys are not associated with constraints")
          end

          def list_table_names_statement : String
            "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
          end
        end
      end
    end
  end
end
