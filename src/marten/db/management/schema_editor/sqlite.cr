module Marten
  module DB
    module Management
      module SchemaEditor
        class SQLite < Base
          def add_column(table : Migrations::TableState, column : Migration::Column::Base)
            remake_table_with_column_change(table, column, change_type: :add)
          end

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
            statements << build_sql do |s|
              s << "UPDATE #{quote("sqlite_sequence")}"
              s << "SET #{quote("seq")} = 0"
              s << "WHERE #{quote("name")} IN (#{table_names.join(", ")})"
            end

            statements
          end

          def prepare_foreign_key_for_new_column(
            table : Migrations::TableState,
            column : Migration::Column::ForeignKey,
            column_definition : String
          ) : String
            raise NotImplementedError.new("Adding foreign keys to tables is not supported by the SQLite schema editor")
          end

          def prepare_foreign_key_for_new_table(
            table : Migrations::TableState,
            column : Migration::Column::ForeignKey,
            column_definition : String
          ) : String
            "#{column_definition} " + build_sql do |s|
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
              s << "DEFERRABLE INITIALLY DEFERRED"
            end
          end

          def rename_table_statement(old_name : String, new_name : String)
            "ALTER TABLE #{old_name} RENAME TO #{new_name}"
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

          private def remake_table_with_column_change(table, column, change_type)
            # Set up a mapping that will hold the link between columns from the original table to the columns of the
            # new table.
            column_names_mapping = {} of String => String
            table.columns.each { |c| column_names_mapping[c.name] = c.name }

            remade_table = table.clone
            remade_table.name = "new_#{remade_table.name}"

            if change_type == :add
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

            # Create the new table.
            create_table(remade_table)

            # Copy data from the old table to the new table.
            @connection.open do |db|
              db.exec(
                build_sql do |s|
                  s << "INSERT INTO #{remade_table.name}"
                  s << "(#{column_names_mapping.keys.map { |name| quote(name) }.join(", ")})"
                  s << "SELECT #{column_names_mapping.values.map { |name| quote(name) }.join(", ")}"
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
