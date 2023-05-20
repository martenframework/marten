require "./concerns/*"

module Marten
  module DB
    module Management
      module SchemaEditor
        class SQLite < Base
          include Core

          def add_column(table : TableState, column : Column::Base) : Nil
            remake_table_with_added_column(table, column)
          end

          def add_unique_constraint(table : TableState, unique_constraint : Management::Constraint::Unique) : Nil
            remake_table_with_added_unique_constraint(table, unique_constraint)
          end

          def change_column(
            project : ProjectState,
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : Nil
            remake_table_with_changed_column(table, old_column, new_column)

            old_type = old_column.sql_type(@connection)
            new_type = new_column.sql_type(@connection)

            # Identifies whether incoming FKs need to be recreated and then recreate the corresponding tables if this is
            # the case.
            remake_fk_columns = old_type != new_type && old_column.primary_key? && new_column.primary_key?
            if remake_fk_columns
              incoming_foreign_keys = project.tables.values.flat_map do |other_table|
                incoming_fk_columns = other_table.columns.select(Column::Reference).select do |fk_column|
                  fk_column.to_table == table.name && fk_column.to_column == old_column.name
                end

                incoming_fk_columns.map { |fk_column| {other_table, fk_column} }
              end

              incoming_foreign_keys.each do |other_table, old_fk_column|
                new_fk_column = old_fk_column.clone
                new_fk_column.target_column = new_column
                new_other_table = other_table.clone
                new_other_table.change_column(new_fk_column)
                with_remade_table(new_other_table) { }
              end
            end
          end

          def column_type_for_built_in_column(column : Column::Base) : String
            BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING[column.class.name]
          end

          def column_type_suffix_for_built_in_column(column : Column::Base) : String?
            column_type_suffix = nil

            if (column.is_a?(Column::BigInt) || column.is_a?(Column::Int)) && column.auto?
              column_type_suffix = "AUTOINCREMENT"
            end

            column_type_suffix
          end

          def ddl_rollbackable? : Bool
            true
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

          def remove_unique_constraint(table : TableState, unique_constraint : Management::Constraint::Unique) : Nil
            remake_table_with_removed_unique_constraint(table, unique_constraint)
          end

          private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
            "Marten::DB::Management::Column::BigInt"   => "integer",
            "Marten::DB::Management::Column::Bool"     => "bool",
            "Marten::DB::Management::Column::Date"     => "date",
            "Marten::DB::Management::Column::DateTime" => "datetime",
            "Marten::DB::Management::Column::Float"    => "real",
            "Marten::DB::Management::Column::Int"      => "integer",
            "Marten::DB::Management::Column::JSON"     => "text",
            "Marten::DB::Management::Column::String"   => "varchar(%{max_size})",
            "Marten::DB::Management::Column::Text"     => "text",
            "Marten::DB::Management::Column::UUID"     => "char(32)",
          }

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

          private def delete_table_statement(table_name : String) : String
            "DROP TABLE #{quote(table_name)}"
          end

          private def flush_tables_statements(table_names : Array(String)) : Array(String)
            statements = [] of String

            table_names.each do |table_name|
              statements << "DELETE FROM #{table_name}"
            end

            # Add a statement to reset table sequences if the sqlite_sequence table exists.
            if sqlite_sequence?
              statements << build_sql do |s|
                s << "UPDATE #{quote("sqlite_sequence")}"
                s << "SET #{quote("seq")} = 0"
                s << "WHERE #{quote("name")} IN (#{table_names.join(", ")})"
              end
            end

            statements
          end

          private def prepare_foreign_key_for_new_table(
            table : TableState,
            column : Column::Reference,
            column_definition : String
          ) : String
            "#{column_definition} " + build_sql do |s|
              s << "REFERENCES #{quote(column.to_table)} (#{quote(column.to_column)})"
              s << "DEFERRABLE INITIALLY DEFERRED"
            end
          end

          private def remake_table_with_added_column(table, column)
            with_remade_table(table) do |remade_table, _column_names_mapping|
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

          private def remake_table_with_added_unique_constraint(table, unique_constraint)
            with_remade_table(table) do |remade_table, _column_names_mapping|
              remade_table.add_unique_constraint(unique_constraint)
            end
          end

          private def remake_table_with_changed_column(table, old_column, new_column)
            with_remade_table(table) do |remade_table, column_names_mapping|
              # If the new column is a primary key, remove the primary key constraint from the the old primary key
              # column.
              if new_column.primary_key?
                remade_table.columns.each do |c|
                  next unless c.primary_key?
                  c.primary_key = false
                end
              end

              remade_table.remove_column(old_column)
              remade_table.add_column(new_column)

              # Enforces new default value (in case the column became not nullable).
              unless new_column.default.nil?
                column_names_mapping[new_column.name] = (
                  "coalesce(#{quote(new_column.name)}, #{new_column.sql_quoted_default_value(@connection)})"
                )
              end
            end
          end

          private def remake_table_with_removed_column(table, column)
            with_remade_table(table) do |remade_table, column_names_mapping|
              remade_table.remove_column(column)
              column_names_mapping.delete(column.name)
            end
          end

          private def remake_table_with_removed_unique_constraint(table, unique_constraint)
            with_remade_table(table) do |remade_table, _column_names_mapping|
              remade_table.remove_unique_constraint(unique_constraint)
            end
          end

          private def remove_index_statement(table : TableState, name : String) : String
            build_sql do |s|
              s << "DROP INDEX"
              s << quote(name)
            end
          end

          private def rename_column_statement(table : TableState, column : Column::Base, new_name : String) : String
            "ALTER TABLE #{quote(table.name)} RENAME COLUMN #{quote(column.name)} TO #{quote(new_name)}"
          end

          private def rename_table_statement(old_name : String, new_name : String) : String
            "ALTER TABLE #{quote(old_name)} RENAME TO #{quote(new_name)}"
          end

          private def sqlite_sequence?
            result = @connection.open do |db|
              db.scalar(
                build_sql do |s|
                  s << "SELECT EXISTS("
                  s << "SELECT 1"
                  s << "FROM #{quote("sqlite_master")}"
                  s << "WHERE #{quote("name")} = #{quote("sqlite_sequence")}"
                  s << ")"
                end
              )
            end

            ["1", "t", "true"].includes?(result.to_s)
          end

          private def with_remade_table(table, &)
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
                  s << "SELECT #{column_names_mapping.values.join(", ")}"
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
