require "./concerns/*"

module Marten
  module DB
    module Management
      module SchemaEditor
        class PostgreSQL < Base
          include Core

          def column_type_for_built_in_column(column : Column::Base) : String
            column_type = BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING[column.class.name]

            if column.is_a?(Column::BigInt) && column.auto?
              column_type = "bigserial"
            elsif column.is_a?(Column::Int) && column.auto?
              column_type = "serial"
            end

            column_type
          end

          def column_type_suffix_for_built_in_column(column : Column::Base) : String?
            nil
          end

          def ddl_rollbackable? : Bool
            true
          end

          def quoted_default_value_for_built_in_column(value : ::DB::Any) : String
            __marten_defined?(::PG) do
              value = case value
                      when Bytes
                        "X'#{value.hexstring}'"
                      when String
                        PG::EscapeHelper.escape_literal(value)
                      when Time
                        "'#{String.new(PQ::Param.encode(value).slice)}'"
                      else
                        value.to_s
                      end
            end

            value.to_s
          end

          private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
            "Marten::DB::Management::Column::BigInt"   => "bigint",
            "Marten::DB::Management::Column::Bool"     => "boolean",
            "Marten::DB::Management::Column::Date"     => "date",
            "Marten::DB::Management::Column::DateTime" => "timestamp with time zone",
            "Marten::DB::Management::Column::Float"    => "double precision",
            "Marten::DB::Management::Column::Int"      => "integer",
            "Marten::DB::Management::Column::JSON"     => "jsonb",
            "Marten::DB::Management::Column::String"   => "varchar(%{max_size})",
            "Marten::DB::Management::Column::Text"     => "text",
            "Marten::DB::Management::Column::UUID"     => "uuid",
          }

          private def add_foreign_key_constraint_statement(table : TableState, column : Column::Reference) : String
            constraint_name = index_name(table.name, [column.name], "_fk_#{column.to_table}_#{column.to_column}")
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "ADD CONSTRAINT #{quote(constraint_name)}"
              s << "FOREIGN KEY (#{quote(column.name)})"
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
              s << "DEFERRABLE INITIALLY DEFERRED"
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
            old_type = BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING.fetch(old_column.class.name, old_column.sql_type(@connection))
            new_type = BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING.fetch(new_column.class.name, new_column.sql_type(@connection))
            new_interpolated_type = new_column.sql_type(@connection)

            new_interpolated_type = if new_interpolated_type == "serial"
                                      "integer"
                                    elsif new_interpolated_type == "bigserial"
                                      "bigint"
                                    else
                                      new_interpolated_type
                                    end

            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "ALTER COLUMN #{quote(new_column.name)} TYPE #{new_interpolated_type}"
              s << "USING #{quote(new_column.name)}::#{new_interpolated_type}" if old_type != new_type
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
            "ALTER TABLE #{quote(table.name)} DROP COLUMN #{quote(column.name)} CASCADE"
          end

          private def delete_foreign_key_constraint_statement(table : TableState, name : String) : String
            "ALTER TABLE #{quote(table.name)} DROP CONSTRAINT #{quote(name)}"
          end

          private def delete_primary_key_constraint_statement(table : TableState, name : String) : String
            "ALTER TABLE #{quote(table.name)} DROP CONSTRAINT #{quote(name)}"
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
              s << "DROP DEFAULT"
            end
          end

          private def flush_tables_statements(table_names : Array(String)) : Array(String)
            ["TRUNCATE #{table_names.join(", ")} RESTART IDENTITY CASCADE;"]
          end

          private def prepare_foreign_key_for_new_column(
            table : TableState,
            column : Column::Reference,
            column_definition : String
          ) : String
            constraint_name = index_name(table.name, [column.name], "_fk_#{column.to_table}_#{column.to_column}")

            "#{column_definition} " + build_sql do |s|
              s << "CONSTRAINT #{quote(constraint_name)}"
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
              s << "DEFERRABLE INITIALLY DEFERRED"
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
                s << "DEFERRABLE INITIALLY DEFERRED"
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
            statements = [] of String

            old_type = old_column.sql_type(@connection)
            new_type = new_column.sql_type(@connection)

            if %w(bigserial serial).includes?(new_type.downcase)
              # If the column became a primary key, a new sequence needs to be created and configured.
              sequence_name = "#{table.name}_#{new_column.name}_seq"

              statements << "DROP SEQUENCE IF EXISTS #{quote(sequence_name)} CASCADE"
              statements << "CREATE SEQUENCE #{quote(sequence_name)}"

              statements << build_sql do |s|
                s << "ALTER TABLE #{quote(table.name)}"
                s << "ALTER COLUMN #{quote(new_column.name)}"
                s << "SET DEFAULT nextval('#{quote(sequence_name)}')"
              end

              statements << build_sql do |s|
                s << "SELECT setval('#{quote(sequence_name)}', MAX(#{quote(new_column.name)}))"
                s << "FROM #{quote(table.name)}"
              end

              statements << build_sql do |s|
                s << "ALTER SEQUENCE #{quote(sequence_name)}"
                s << "OWNED BY #{quote(table.name)}.#{quote(new_column.name)}"
              end
            elsif %w(bigserial serial).includes?(old_type.downcase)
              # If the column was previously a primary key, the associated sequence needs to be dropped.
              sequence_name = "#{table.name}_#{old_column.name}_seq"
              statements << "DROP SEQUENCE IF EXISTS #{quote(sequence_name)} CASCADE"
            end

            statements
          end

          private def remove_index_statement(table : TableState, name : String) : String
            build_sql do |s|
              s << "DROP INDEX IF EXISTS"
              s << quote(name)
            end
          end

          private def remove_unique_constraint_statement(table : TableState, name : String) : String
            build_sql do |s|
              s << "ALTER TABLE"
              s << table.name
              s << "DROP CONSTRAINT"
              s << name
            end
          end

          private def rename_column_statement(table : TableState, column : Column::Base, new_name : String) : String
            "ALTER TABLE #{quote(table.name)} RENAME COLUMN #{quote(column.name)} TO #{quote(new_name)}"
          end

          private def rename_table_statement(old_name : String, new_name : String) : String
            "ALTER TABLE #{quote(old_name)} RENAME TO #{quote(new_name)}"
          end

          private def set_up_not_null_column_statement(
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : String
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "ALTER COLUMN #{quote(new_column.name)}"
              s << "SET NOT NULL"
            end
          end

          private def set_up_null_column_statement(
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : String
            build_sql do |s|
              s << "ALTER TABLE #{quote(table.name)}"
              s << "ALTER COLUMN #{quote(new_column.name)}"
              s << "DROP NOT NULL"
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
