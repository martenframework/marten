module Marten
  module DB
    module Management
      module Introspector
        class PostgreSQL < Base
          def get_foreign_key_constraint_names_statement(table_name : String) : String
            build_sql do |s|
              s << "SELECT c.conname"
              s << "FROM pg_constraint AS c"
              s << "JOIN pg_class AS cl ON c.conrelid = cl.oid"
              s << "WHERE cl.relname = '#{table_name}'"
              s << "AND pg_catalog.pg_table_is_visible(cl.oid) AND c.contype = 'f'"
            end
          end

          def list_table_names_statement : String
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
          end
        end
      end
    end
  end
end
