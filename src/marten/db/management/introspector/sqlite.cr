module Marten
  module DB
    module Management
      module Introspector
        class SQLite < Base
          def list_table_names_statement : String
            "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
          end
        end
      end
    end
  end
end
