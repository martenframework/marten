module Marten
  module DB
    module Management
      module SchemaEditor
        class SQLite < Base
          def column_type_for_built_in_column(id)
            BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING[id]
          end

          def column_type_suffix_for_built_in_column(id)
            BUILT_IN_COLUMN_TO_DB_TYPE_SUFFIX_MAPPING[id]?
          end

          def create_index_statement(name : String, table_name : String, columns : Array(String)) : String
            "CREATE INDEX #{name} ON #{table_name} (#{columns.join(", ")})"
          end

          def create_table_statement(table_name : String, column_definitions : String) : String
            "CREATE TABLE #{table_name} (#{column_definitions})"
          end

          def ddl_rollbackable? : Bool
            true
          end

          def delete_table_statement(table_name : String) : String
            "DROP TABLE #{table_name}"
          end

          def flush_tables_statements(table_names : Array(String)) : Array(String)
            statements = [] of String

            table_names.each do |table_name|
              statements << "DELETE FROM #{table_name}"
            end

            # Add a statement to reset table sequences.
            statements <<
              "UPDATE #{@connection.quote("sqlite_sequence")} " \
              "SET #{@connection.quote("seq")} = 0 " \
              "WHERE #{@connection.quote("name")} IN (#{table_names.join(", ")})"

            statements
          end

          private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
            "Marten::DB::Migration::Column::Auto"       => "integer",
            "Marten::DB::Migration::Column::BigAuto"    => "integer",
            "Marten::DB::Migration::Column::BigInt"     => "integer",
            "Marten::DB::Migration::Column::Bool"       => "bool",
            "Marten::DB::Migration::Column::DateTime"   => "datetime",
            "Marten::DB::Migration::Column::ForeignKey" => "integer",
            "Marten::DB::Migration::Column::Int"        => "integer",
            "Marten::DB::Migration::Column::String"     => "varchar(%{max_size})",
            "Marten::DB::Migration::Column::Text"       => "text",
            "Marten::DB::Migration::Column::UUID"       => "char(32)",
          }

          private BUILT_IN_COLUMN_TO_DB_TYPE_SUFFIX_MAPPING = {
            "Marten::DB::Migration::Column::Auto"    => "AUTOINCREMENT",
            "Marten::DB::Migration::Column::BigAuto" => "AUTOINCREMENT",
          }
        end
      end
    end
  end
end
