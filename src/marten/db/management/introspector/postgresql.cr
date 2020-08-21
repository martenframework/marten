module Marten
  module DB
    module Management
      module Introspector
        class PostgreSQL < Base
          def list_table_names_statement : String
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
          end
        end
      end
    end
  end
end
