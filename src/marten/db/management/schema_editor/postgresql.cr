module Marten
  module DB
    module Management
      module SchemaEditor
        class PostgreSQL < Base
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
            true
          end

          def delete_table_statement(table_name : String) : String
            "DROP TABLE #{table_name} CASCADE"
          end

          def flush_tables_statements(table_names : Array(String)) : Array(String)
            ["TRUNCATE #{table_names.join(", ")} RESTART IDENTITY;"]
          end

          def prepare_foreign_key_for_new_column(
            table : Migrations::TableState,
            column : Migration::Column::ForeignKey,
            column_definition : String
          ) : String
            constraint_name = index_name(table.name, [column.name]) + "_fk_#{column.to_table}_#{column.to_column}"

            "#{column_definition} " + build_sql do |s|
              s << "CONSTRAINT #{quote(constraint_name)}"
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
              s << "DEFERRABLE INITIALLY DEFERRED"
            end
          end

          def prepare_foreign_key_for_new_table(
            table : Migrations::TableState,
            column : Migration::Column::ForeignKey,
            column_definition : String
          ) : String
            constraint_name = index_name(table.name, [column.name]) + "_fk_#{column.to_table}_#{column.to_column}"

            @deferred_statements << build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "ADD CONSTRAINT #{quote(constraint_name)}"
              s << "FOREIGN KEY (#{quote(column.name)})"
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
              s << "DEFERRABLE INITIALLY DEFERRED"
            end

            # Returns the initial column definition since the foreign key creation is deferred.
            column_definition
          end

          private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
            "Marten::DB::Migration::Column::Auto"       => "serial",
            "Marten::DB::Migration::Column::BigAuto"    => "bigserial",
            "Marten::DB::Migration::Column::BigInt"     => "bigint",
            "Marten::DB::Migration::Column::Bool"       => "boolean",
            "Marten::DB::Migration::Column::DateTime"   => "timestamp with time zone",
            "Marten::DB::Migration::Column::ForeignKey" => "bigint",
            "Marten::DB::Migration::Column::Int"        => "integer",
            "Marten::DB::Migration::Column::String"     => "varchar(%{max_size})",
            "Marten::DB::Migration::Column::Text"       => "text",
            "Marten::DB::Migration::Column::UUID"       => "uuid",
          }
        end
      end
    end
  end
end
