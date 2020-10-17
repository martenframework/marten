module Marten
  module DB
    module Management
      module Introspector
        class MySQL < Base
          def list_table_names_statement : String
            "SHOW TABLES"
          end
        end
      end
    end
  end
end
