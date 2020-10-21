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

          def prepare_foreign_key_for_new_table(
            table : Migrations::TableState,
            column : Migration::Column::ForeignKey,
            column_definition : String
          ) : String
            constraint_name = index_name(table.name, [column.name]) + "_fk_#{column.to_table}_#{column.to_column}"
            @deferred_statements << "ALTER TABLE #{quote(table.name)} ADD CONSTRAINT #{quote(constraint_name)} " \
                                    "FOREIGN KEY (#{quote(column.name)}) " \
                                    "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"

            # Returns the initial column definition since the foreign key creation is deferred.
            column_definition
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
