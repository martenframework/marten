module Marten
  module DB
    module Management
      module SchemaEditor
        class SQLite < Base
          def add_column(table : TableState, column : Column::Base)
            remake_table_with_added_column(table, column)
          end

          def column_type_for_built_in_column(id)
            BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING[id]
          end

          def column_type_suffix_for_built_in_column(id)
            BUILT_IN_COLUMN_TO_DB_TYPE_SUFFIX_MAPPING[id]?
          end

          def create_index_deferred_statement(table : TableState, columns : Array(Column::Base)) : Statement
            Statement.new(
              "CREATE INDEX %{name} ON %{table} (%{columns})",
              name: statement_index_name(table.name, columns.map(&.name)),
              table: statement_table(table.name),
              columns: statement_columns(table.name, columns.map(&.name)),
            )
          end

          def create_table_statement(table_name : String, definitions : String) : String
            "CREATE TABLE #{table_name} (#{definitions})"
          end

          def ddl_rollbackable? : Bool
            true
          end

          def delete_column_statement(table : TableState, column : Column::Base) : String
            raise NotImplementedError.new(
              "Deleting columns from tables through SQL is not supported by the SQLite schema editor"
            )
          end

          def delete_foreign_key_constraint_statement(table : TableState, name : String) : String
            raise NotImplementedError.new(
              "Removing foreign keys from tables is not supported by the SQLite schema editor"
            )
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
            statements << build_sql do |s|
              s << "UPDATE #{quote("sqlite_sequence")}"
              s << "SET #{quote("seq")} = 0"
              s << "WHERE #{quote("name")} IN (#{table_names.join(", ")})"
            end

            statements
          end

          def prepare_foreign_key_for_new_column(
            table : TableState,
            column : Column::ForeignKey,
            column_definition : String
          ) : String
            raise NotImplementedError.new("Adding foreign keys to tables is not supported by the SQLite schema editor")
          end

          def prepare_foreign_key_for_new_table(
            table : TableState,
            column : Column::ForeignKey,
            column_definition : String
          ) : String
            "#{column_definition} " + build_sql do |s|
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
              s << "DEFERRABLE INITIALLY DEFERRED"
            end
          end

          def quoted_default_value_for_built_in_column(value : ::DB::Any) : String
            case value
            when Bool
              (value ? 1 : 0).to_s
            when Bytes
              "X'#{value.hexstring}'"
            when String
              "'#{value.gsub("'", "''")}'"
            when Time
              "'#{value.to_utc.to_s("%F %H:%M:%S.%L")}'"
            else
              value.to_s
            end
          end

          def remove_column(table : TableState, column : Column::Base) : Nil
            remake_table_with_removed_column(table, column)
          end

          def rename_column_statement(table : TableState, column : Column::Base, new_name : String) : String
            "ALTER TABLE #{quote(table.name)} RENAME COLUMN #{quote(column.name)} TO #{quote(new_name)}"
          end

          def rename_table_statement(old_name : String, new_name : String) : String
            "ALTER TABLE #{old_name} RENAME TO #{new_name}"
          end

          private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
            "Marten::DB::Management::Column::Auto"       => "integer",
            "Marten::DB::Management::Column::BigAuto"    => "integer",
            "Marten::DB::Management::Column::BigInt"     => "integer",
            "Marten::DB::Management::Column::Bool"       => "bool",
            "Marten::DB::Management::Column::DateTime"   => "datetime",
            "Marten::DB::Management::Column::ForeignKey" => "integer",
            "Marten::DB::Management::Column::Int"        => "integer",
            "Marten::DB::Management::Column::String"     => "varchar(%{max_size})",
            "Marten::DB::Management::Column::Text"       => "text",
            "Marten::DB::Management::Column::UUID"       => "char(32)",
          }

          private BUILT_IN_COLUMN_TO_DB_TYPE_SUFFIX_MAPPING = {
            "Marten::DB::Management::Column::Auto"    => "AUTOINCREMENT",
            "Marten::DB::Management::Column::BigAuto" => "AUTOINCREMENT",
          }

          private def remake_table_with_added_column(table, column)
            with_remade_table(table) do |remade_table, column_names_mapping|
              # If the new column is a primary key, remove the primary key constraint from the the old primary key
              # column.
              if column.primary_key?
                remade_table.columns.each do |c|
                  next unless c.primary_key?
                  c.primary_key = false
                end
              end

              remade_table.add_column(column)
            end
          end

          private def remake_table_with_removed_column(table, column)
            with_remade_table(table) do |remade_table, column_names_mapping|
              remade_table.remove_column(column)
              column_names_mapping.delete(column.name)
            end
          end

          def with_remade_table(table)
            # Set up a mapping that will hold the link between columns from the original table to the columns of the
            # new table.
            column_names_mapping = {} of String => String
            table.columns.each { |c| column_names_mapping[c.name] = c.name }

            remade_table = table.clone
            remade_table.name = "new_#{remade_table.name}"

            yield remade_table, column_names_mapping

            # Create the new table.
            create_table(remade_table)

            # Copy data from the old table to the new table.
            @connection.open do |db|
              db.exec(
                build_sql do |s|
                  s << "INSERT INTO #{remade_table.name}"
                  s << "(#{column_names_mapping.keys.join(", ") { |name| quote(name) }})"
                  s << "SELECT #{column_names_mapping.values.join(", ") { |name| quote(name) }}"
                  s << "FROM #{table.name}"
                end
              )
            end

            # Delete the old table and rename the new one.
            delete_table(table)
            rename_table(remade_table, table.name)

            # Runs the deferred statements on the remade table.
            execute_deferred_statements
          end
        end
      end
    end
  end
end
