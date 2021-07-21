module Marten
  module DB
    module Management
      module Introspector
        class PostgreSQL < Base
          def get_foreign_key_constraint_names_statement(table_name : String, column_name : String) : String
            build_sql do |s|
              s << "SELECT c.conname"
              s << "FROM pg_constraint AS c"
              s << "JOIN pg_class AS cl ON c.conrelid = cl.oid"
              s << "WHERE cl.relname = '#{table_name}'"
              s << "AND pg_catalog.pg_table_is_visible(cl.oid) AND c.contype = 'f'"
              s << "AND '#{column_name}'=ANY(array("
              s << "  SELECT attname"
              s << "  FROM unnest(c.conkey) WITH ORDINALITY cols(colid, arridx)"
              s << "  JOIN pg_attribute AS ca ON cols.colid = ca.attnum"
              s << "  WHERE ca.attrelid = c.conrelid"
              s << "  ORDER BY cols.arridx"
              s << "))"
            end
          end

          def get_unique_constraint_names_statement(table_name : String, column_name : String) : String
            build_sql do |s|
              s << "SELECT c.conname"
              s << "FROM pg_constraint AS c"
              s << "JOIN pg_class AS cl ON c.conrelid = cl.oid"
              s << "WHERE cl.relname = '#{table_name}'"
              s << "AND pg_catalog.pg_table_is_visible(cl.oid) AND (c.contype = 'u' OR c.contype = 'p')"
              s << "AND '#{column_name}'=ANY(array("
              s << "  SELECT attname"
              s << "  FROM unnest(c.conkey) WITH ORDINALITY cols(colid, arridx)"
              s << "  JOIN pg_attribute AS ca ON cols.colid = ca.attnum"
              s << "  WHERE ca.attrelid = c.conrelid"
              s << "  ORDER BY cols.arridx"
              s << "))"
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
