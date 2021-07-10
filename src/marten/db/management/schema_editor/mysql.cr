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

          def create_index_deferred_statement(
            table : TableState,
            columns : Array(Column::Base),
            name : String? = nil
          ) : Statement
            Statement.new(
              "CREATE INDEX %{name} ON %{table} (%{columns})",
              name: name.try(&.to_s) || statement_index_name(table.name, columns.map(&.name)),
              table: statement_table(table.name),
              columns: statement_columns(table.name, columns.map(&.name)),
            )
          end

          def create_table_statement(table_name : String, definitions : String) : String
            "CREATE TABLE #{table_name} (#{definitions})"
          end

          def ddl_rollbackable? : Bool
            false
          end

          def delete_column_statement(table : TableState, column : Column::Base) : String
            "ALTER TABLE #{quote(table.name)} DROP COLUMN #{quote(column.name)}"
          end

          def delete_foreign_key_constraint_statement(table : TableState, name : String) : String
            "ALTER TABLE #{quote(table.name)} DROP CONSTRAINT #{quote(name)}"
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

          def prepare_foreign_key_for_new_column(
            table : TableState,
            column : Column::ForeignKey,
            column_definition : String
          ) : String
            constraint_name = index_name(table.name, [column.name], "_fk_#{column.to_table}_#{column.to_column}")

            "#{column_definition}, " + build_sql do |s|
              s << "ADD CONSTRAINT #{quote(constraint_name)}"
              s << "FOREIGN KEY (#{quote(column.name)})"
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
            end
          end

          def prepare_foreign_key_for_new_table(
            table : TableState,
            column : Column::ForeignKey,
            column_definition : String
          ) : String
            @deferred_statements << Statement.new(
              build_sql do |s|
                s << "ALTER TABLE %{table}"
                s << "ADD CONSTRAINT %{constraint}"
                s << "FOREIGN KEY (%{column})"
                s << "REFERENCES %{to_table} (%{to_column})"
              end,
              table: statement_table(table.name),
              constraint: statement_foreign_key_name(table.name, column.name, column.to_table, column.to_column),
              column: statement_columns(table.name, [column.name]),
              to_table: statement_table(column.to_table),
              to_column: statement_columns(column.to_table, [column.to_column]),
            )

            # Returns the initial column definition since the foreign key creation is deferred.
            column_definition
          end

          def quoted_default_value_for_built_in_column(value : ::DB::Any) : String
            defined?(::MySql) do
              value = case value
                      when Bytes
                        "X'#{value.hexstring}'"
                      when String, Time
                        "'#{::MySql::Type.to_mysql(value)}'"
                      else
                        ::MySql::Type.to_mysql(value).to_s
                      end
            end

            value.to_s
          end

          def remove_unique_constraint_statement(
            table : TableState,
            unique_constraint : Management::Constraint::Unique
          ) : String
            build_sql do |s|
              s << "ALTER TABLE"
              s << table.name
              s << "DROP INDEX"
              s << unique_constraint.name
            end
          end

          def rename_column_statement(table : TableState, column : Column::Base, new_name : String) : String
            "ALTER TABLE #{quote(table.name)} CHANGE #{quote(column.name)} #{quote(new_name)} #{column_sql_for(column)}"
          end

          def rename_table_statement(old_name : String, new_name : String) : String
            "RENAME TABLE #{old_name} TO #{new_name}"
          end

          private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
            "Marten::DB::Management::Column::Auto"       => "integer AUTO_INCREMENT",
            "Marten::DB::Management::Column::BigAuto"    => "bigint AUTO_INCREMENT",
            "Marten::DB::Management::Column::BigInt"     => "bigint",
            "Marten::DB::Management::Column::Bool"       => "bool",
            "Marten::DB::Management::Column::DateTime"   => "datetime(6)",
            "Marten::DB::Management::Column::ForeignKey" => "bigint",
            "Marten::DB::Management::Column::Int"        => "integer",
            "Marten::DB::Management::Column::String"     => "varchar(%{max_size})",
            "Marten::DB::Management::Column::Text"       => "longtext",
            "Marten::DB::Management::Column::UUID"       => "char(32)",
          }
        end
      end
    end
  end
end
