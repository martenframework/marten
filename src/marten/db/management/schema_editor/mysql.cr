module Marten
  module DB
    module Management
      module SchemaEditor
        class MySQL < Base
          def column_type_for_built_in_column(id)
            BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING[id]
          end

          def column_type_suffix_for_built_in_column(id)
            nil
          end

          def create_index_statement(name : String, table_name : String, columns : Array(String)) : String
            "CREATE INDEX #{name} ON #{table_name} (#{columns.join(", ")})"
          end

          def create_table_statement(table_name : String, column_definitions : String) : String
            "CREATE TABLE #{table_name} (#{column_definitions})"
          end

          def ddl_rollbackable? : Bool
            false
          end

          def delete_table_statement(table_name : String) : String
            "DROP TABLE #{table_name} CASCADE"
          end

          def flush_tables_statements(table_names : Array(String)) : Array(String)
            statements = [] of String

            statements << "SET FOREIGN_KEY_CHECKS = 0"

            table_names.each do |table_name|
              statements << "TRUNCATE #{table_name}"
            end

            statements << "SET FOREIGN_KEY_CHECKS = 1"

            statements
          end

          private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
            "Marten::DB::Migration::Column::Auto"       => "integer AUTO_INCREMENT",
            "Marten::DB::Migration::Column::BigAuto"    => "bigint AUTO_INCREMENT",
            "Marten::DB::Migration::Column::BigInt"     => "bigint",
            "Marten::DB::Migration::Column::Bool"       => "bool",
            "Marten::DB::Migration::Column::DateTime"   => "datetime(6)",
            "Marten::DB::Migration::Column::ForeignKey" => "bigint",
            "Marten::DB::Migration::Column::Int"        => "integer",
            "Marten::DB::Migration::Column::String"     => "varchar(%{max_size})",
            "Marten::DB::Migration::Column::Text"       => "longtext",
            "Marten::DB::Migration::Column::UUID"       => "char(32)",
          }
        end
      end
    end
  end
end
