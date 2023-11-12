require "./concerns/*"

module Marten
  module DB
    module Management
      module Introspector
        class MySQL < Base
          include Core

          def columns_details(table_name : String) : Array(ColumnInfo)
            results = [] of ColumnInfo

            @connection.open do |db|
              db.query(
                build_sql do |s|
                  s << "SELECT column_name, CAST(data_type AS CHAR(255)), is_nullable, column_default, " \
                       "character_maximum_length"
                  s << "FROM information_schema.columns"
                  s << "WHERE table_name = '#{table_name}' AND table_schema = DATABASE()"
                end
              ) do |rs|
                rs.each do
                  column_name = rs.read(String)
                  type = rs.read(String)
                  is_nullable = (rs.read(String) == "YES")
                  column_default = rs.read(::DB::Any)
                  character_maximum_length = rs.read(Int32 | Int64 | Nil)
                  results << ColumnInfo.new(
                    name: column_name,
                    type: type,
                    nullable: is_nullable,
                    default: column_default,
                    character_maximum_length: character_maximum_length
                  )
                end
              end
            end

            results
          end

          def foreign_key_constraint_names(table_name : String, column_name : String) : Array(String)
            names = [] of String

            @connection.open do |db|
              db.query(
                build_sql do |s|
                  s << "SELECT c.constraint_name"
                  s << "FROM information_schema.key_column_usage AS c"
                  s << "WHERE c.table_schema = DATABASE() AND c.table_name = '#{table_name}'"
                  s << "AND c.column_name = '#{column_name}'"
                  s << "AND c.referenced_column_name IS NOT NULL"
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
              db.query("SHOW INDEX FROM #{quote(table_name)}") do |rs|
                rs.each do
                  rs.read(String) # table
                  rs.read(Bool)   # non_unique
                  index_name = rs.read(String)
                  rs.read(Int32 | Int64) # seq_in_index
                  index_column_name = rs.read(String)

                  indexes_to_columns[index_name] ||= [] of String
                  indexes_to_columns[index_name] << index_column_name
                end
              end
            end

            indexes_to_columns.select { |_k, v| v == [column_name] }.keys
          end

          def primary_key_constraint_names(table_name : String, column_name : String) : Array(String)
            names = [] of String

            @connection.open do |db|
              db.query(
                build_sql do |s|
                  s << "SELECT kcu.constraint_name"
                  s << "FROM information_schema.key_column_usage AS kcu, information_schema.table_constraints AS tc"
                  s << "WHERE kcu.table_schema = DATABASE()"
                  s << "AND tc.table_schema = kcu.table_schema"
                  s << "AND tc.constraint_name = kcu.constraint_name"
                  s << "AND tc.table_name = kcu.table_name"
                  s << "AND tc.constraint_type = 'PRIMARY KEY'"
                  s << "AND kcu.table_name = '#{table_name}'"
                  s << "AND kcu.column_name = '#{column_name}'"
                end
              ) do |rs|
                rs.each do
                  names << rs.read(String)
                end
              end
            end

            names
          end

          def unique_constraint_names(table_name : String, column_name : String) : Array(String)
            names = [] of String

            @connection.open do |db|
              db.query(
                build_sql do |s|
                  s << "SELECT kc.constraint_name"
                  s << "FROM information_schema.key_column_usage AS kc, "
                  s << "information_schema.table_constraints AS c"
                  s << "WHERE kc.table_schema = DATABASE() AND kc.table_name = '#{table_name}'"
                  s << "AND kc.column_name = '#{column_name}'"
                  s << "AND c.table_schema = kc.table_schema"
                  s << "AND c.table_name = kc.table_name"
                  s << "AND c.constraint_name = kc.constraint_name"
                  s << "AND (c.constraint_type = 'PRIMARY KEY' OR c.constraint_type = 'UNIQUE')"
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
            "SHOW TABLES"
          end
        end
      end
    end
  end
end
