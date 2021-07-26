require "./concerns/*"

module Marten
  module DB
    module Management
      module Introspector
        class PostgreSQL < Base
          include Core

          def foreign_key_constraint_names(table_name : String, column_name : String) : Array(String)
            names = [] of String

            @connection.open do |db|
              db.query(
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
              ) do |rs|
                rs.each do
                  names << rs.read(String)
                end
              end
            end

            names
          end

          def index_names(table_name : String, column_name : String) : Array(String)
            indexes_to_columns = {} of String => Array(String)

            @connection.open do |db|
              db.query(
                build_sql do |s|
                  s << "SELECT i.relname AS index_name, a.attname AS column_name"
                  s << "FROM pg_class t, pg_class i, pg_index ix, pg_attribute a"
                  s << "WHERE t.oid = ix.indrelid"
                  s << "AND i.oid = ix.indexrelid"
                  s << "AND a.attrelid = t.oid"
                  s << "AND a.attnum = ANY(ix.indkey)"
                  s << "AND t.relkind = 'r'"
                  s << "AND t.relname = '#{table_name}'"
                end
              ) do |rs|
                rs.each do
                  index_name = rs.read(String)
                  index_column_name = rs.read(String)

                  indexes_to_columns[index_name] ||= [] of String
                  indexes_to_columns[index_name] << index_column_name
                end
              end
            end

            indexes_to_columns.select { |_k, v| v == [column_name] }.keys
          end

          def unique_constraint_names(table_name : String, column_name : String) : Array(String)
            names = [] of String

            @connection.open do |db|
              db.query(
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
              ) do |rs|
                rs.each do
                  names << rs.read(String)
                end
              end
            end

            names
          end

          private def list_table_names_statement
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
          end
        end
      end
    end
  end
end
