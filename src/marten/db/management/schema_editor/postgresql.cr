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
            table : TableState,
            column : Column::ForeignKey,
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
            table : TableState,
            column : Column::ForeignKey,
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

          def rename_table_statement(old_name : String, new_name : String)
            "ALTER TABLE #{old_name} RENAME TO #{new_name}"
          end

          private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
            "Marten::DB::Management::Column::Auto"       => "serial",
            "Marten::DB::Management::Column::BigAuto"    => "bigserial",
            "Marten::DB::Management::Column::BigInt"     => "bigint",
            "Marten::DB::Management::Column::Bool"       => "boolean",
            "Marten::DB::Management::Column::DateTime"   => "timestamp with time zone",
            "Marten::DB::Management::Column::ForeignKey" => "bigint",
            "Marten::DB::Management::Column::Int"        => "integer",
            "Marten::DB::Management::Column::String"     => "varchar(%{max_size})",
            "Marten::DB::Management::Column::Text"       => "text",
            "Marten::DB::Management::Column::UUID"       => "uuid",
          }
        end
      end
    end
  end
end
