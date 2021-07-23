module Marten
  module DB
    module Management
      module Introspector
        class SQLite < Base
          def foreign_key_constraint_names(table_name : String, column_name : String) : Array(String)
            [] of String
          end

          def index_names(table_name : String, column_name : String) : Array(String)
            indexes_to_columns = {} of String => Array(String)

            @connection.open do |db|
              db.query(
                build_sql do |s|
                  s << "SELECT il.name, ii.name"
                  s << "FROM sqlite_master AS m, pragma_index_list(m.name) AS il, pragma_index_info(il.name) AS ii"
                  s << "WHERE m.type='table' AND m.tbl_name='#{table_name}'"
                  s << "ORDER BY 1;"
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

          def list_table_names_statement : String
            "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
          end

          def unique_constraint_names(table_name : String, column_name : String) : Array(String)
            unique_indexes_to_columns = {} of String => Array(String)

            @connection.open do |db|
              db.query(
                build_sql do |s|
                  s << "SELECT il.name AS constraint_name, ii.name AS column_name"
                  s << "FROM sqlite_master AS m, pragma_index_list(m.name) AS il, pragma_index_info(il.name) AS ii"
                  s << "WHERE m.type = 'table' AND il.origin = 'u' AND m.tbl_name = '#{table_name}'"
                end
              ) do |rs|
                rs.each do
                  constraint_name = rs.read(String)
                  constraint_column_name = rs.read(String)
                  unique_indexes_to_columns[constraint_name] ||= [] of String
                  unique_indexes_to_columns[constraint_name] << constraint_column_name
                end
              end
            end

            unique_indexes_to_columns.select { |_k, v| v == [column_name] }.keys
          end
        end
      end
    end
  end
end
