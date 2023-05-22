require "./concerns/*"

module Marten
  module DB
    module Management
      module SchemaEditor
        class MySQL < Base
          include Core

          def column_type_for_built_in_column(column : Column::Base) : String
            column_type = BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING[column.class.name]

            if (column.is_a?(Column::BigInt) || column.is_a?(Column::Int)) && column.auto?
              column_type += " AUTO_INCREMENT"
            end

            column_type
          end

          def column_type_suffix_for_built_in_column(column : Column::Base) : String?
            nil
          end

          def ddl_rollbackable? : Bool
            false
          end

          def quoted_default_value_for_built_in_column(value : ::DB::Any) : String
            __marten_defined?(::MySql) do
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

          private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
            "Marten::DB::Management::Column::BigInt"   => "bigint",
            "Marten::DB::Management::Column::Bool"     => "bool",
            "Marten::DB::Management::Column::Date"     => "date",
            "Marten::DB::Management::Column::DateTime" => "datetime(6)",
            "Marten::DB::Management::Column::Float"    => "double precision",
            "Marten::DB::Management::Column::Int"      => "integer",
            "Marten::DB::Management::Column::JSON"     => "text",
            "Marten::DB::Management::Column::String"   => "varchar(%{max_size})",
            "Marten::DB::Management::Column::Text"     => "longtext",
            "Marten::DB::Management::Column::UUID"     => "char(32)",
          }

          private def add_foreign_key_constraint_statement(table : TableState, column : Column::Reference) : String
            constraint_name = index_name(table.name, [column.name], "_fk_#{column.to_table}_#{column.to_column}")
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "ADD CONSTRAINT #{quote(constraint_name)}"
              s << "FOREIGN KEY (#{quote(column.name)})"
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
            end
          end

          private def add_primary_key_constraint_statement(table : TableState, column : Column::Base) : String
            constraint_name = index_name(table.name, [column.name], "_pk")
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "ADD CONSTRAINT #{quote(constraint_name)}"
              s << "PRIMARY KEY (#{quote(column.name)})"
            end
          end

          private def change_column_default_statement(
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : String
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "ALTER COLUMN #{quote(new_column.name)}"
              s << "SET DEFAULT #{new_column.sql_quoted_default_value(@connection)}"
            end
          end

          private def change_column_type_statement(
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : String
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "MODIFY #{quote(new_column.name)} #{new_column.sql_type(@connection)}"
            end
          end

          private def create_index_deferred_statement(
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

          private def create_table_statement(table_name : String, definitions : String) : String
            "CREATE TABLE #{quote(table_name)} (#{definitions})"
          end

          private def delete_column_statement(table : TableState, column : Column::Base) : String
            "ALTER TABLE #{quote(table.name)} DROP COLUMN #{quote(column.name)}"
          end

          private def delete_foreign_key_constraint_statement(table : TableState, name : String) : String
            "ALTER TABLE #{quote(table.name)} DROP CONSTRAINT #{quote(name)}"
          end

          private def delete_primary_key_constraint_statement(table : TableState, name : String) : String
            "ALTER TABLE #{quote(table.name)} DROP PRIMARY KEY"
          end

          private def delete_table_statement(table_name : String) : String
            "DROP TABLE #{quote(table_name)} CASCADE"
          end

          private def drop_column_default_statement(
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : String
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "ALTER COLUMN #{quote(new_column.name)}"
              s << if new_column.null?
                "SET DEFAULT NULL"
              else
                "DROP DEFAULT"
              end
            end
          end

          private def flush_tables_statements(table_names : Array(String)) : Array(String)
            statements = [] of String

            statements << "SET FOREIGN_KEY_CHECKS = 0"

            table_names.each do |table_name|
              statements << "TRUNCATE #{table_name}"
            end

            statements << "SET FOREIGN_KEY_CHECKS = 1"

            statements
          end

          private def prepare_foreign_key_for_new_column(
            table : TableState,
            column : Column::Reference,
            column_definition : String
          ) : String
            constraint_name = index_name(table.name, [column.name], "_fk_#{column.to_table}_#{column.to_column}")

            "#{column_definition}, " + build_sql do |s|
              s << "ADD CONSTRAINT #{quote(constraint_name)}"
              s << "FOREIGN KEY (#{quote(column.name)})"
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
            end
          end

          private def prepare_foreign_key_for_new_table(
            table : TableState,
            column : Column::Reference,
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

          private def post_change_column_type_statements(
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : Array(String)
            [] of String
          end

          private def remove_index_statement(table : TableState, name : String) : String
            build_sql do |s|
              s << "DROP INDEX"
              s << quote(name)
              s << "ON"
              s << table.name
            end
          end

          private def remove_unique_constraint_statement(table : TableState, name : String) : String
            build_sql do |s|
              s << "ALTER TABLE"
              s << table.name
              s << "DROP INDEX"
              s << name
            end
          end

          private def rename_column_statement(table : TableState, column : Column::Base, new_name : String) : String
            "ALTER TABLE #{quote(table.name)} CHANGE #{quote(column.name)} #{quote(new_name)} #{column_sql_for(column)}"
          end

          private def rename_table_statement(old_name : String, new_name : String) : String
            "RENAME TABLE #{quote(old_name)} TO #{quote(new_name)}"
          end

          private def set_up_not_null_column_statement(
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : String
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "MODIFY #{quote(new_column.name)} #{new_column.sql_type(@connection)}"
              # Re-enforces the new default since MySQL won't set a default if the column is nullable.
              s << "DEFAULT #{new_column.sql_quoted_default_value(@connection)}" if !new_column.default.nil?
              s << "NOT NULL"
            end
          end

          private def set_up_null_column_statement(
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : String
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "MODIFY #{quote(new_column.name)} #{new_column.sql_type(@connection)} NULL"
            end
          end

          private def update_null_columns_with_default_value_statement(
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : String
            build_sql do |s|
              s << "UPDATE #{quote(table.name)}"
              s << "SET #{quote(new_column.name)} = #{new_column.sql_quoted_default_value(@connection)}"
              s << "WHERE #{quote(new_column.name)} IS NULL"
            end
          end
        end
      end
    end
  end
end
