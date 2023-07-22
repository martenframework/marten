module Marten
  module DB
    module Management
      module SchemaEditor
        # Base implementation of a database schema editor.
        #
        # The database schema editor is used in the context of DB management in order to perform operation on models:
        # create / delete models, add new fields, etc. It's heavily used by the migrations mechanism.
        abstract class Base
          getter deferred_statements

          def initialize(@connection : Connection::Base)
            @deferred_statements = [] of Statement
          end

          # Adds a column to a specific table.
          abstract def add_column(table : TableState, column : Column::Base) : Nil

          # Adds an index to a specific table.
          abstract def add_index(table : TableState, index : Management::Index) : Nil

          # Adds a unique constraint to a specific table.
          abstract def add_unique_constraint(
            table : TableState,
            unique_constraint : Management::Constraint::Unique
          ) : Nil

          # Changes a column on a specific table.
          abstract def change_column(
            project : ProjectState,
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : Nil

          # Returns the database type for a specific built-in column implementation.
          #
          # Note that this method is only used when handling column types of Marten built-in types as custom column
          # implementations must define a `#db_type` method.
          abstract def column_type_for_built_in_column(column : Column::Base) : String

          # Returns the database type suffix for a specific built-in column implementation.
          #
          # Note that this method is only used when handling column types of Marten built-in types.
          abstract def column_type_suffix_for_built_in_column(column : Column::Base) : String?

          # Creates a new table from a migration table state.
          abstract def create_table(table : TableState) : Nil

          # Returns a boolean indicating if the schema editor implementation supports rollbacking DDL statements.
          abstract def ddl_rollbackable? : Bool

          # Deletes the a specific table.
          abstract def delete_table(name : String) : Nil

          # Flushes all the tables associated with the passed table names.
          abstract def flush_tables(table_names : Array(String)) : Nil

          # Returns a prepared default value that can be inserted in a column definition.
          abstract def quoted_default_value_for_built_in_column(value : ::DB::Any) : String

          # Removes a column from a specific table.
          abstract def remove_column(table : TableState, column : Column::Base) : Nil

          # Removes an index from a specific table.
          abstract def remove_index(table : TableState, index : Management::Index) : Nil

          # Removes a unique constraint from a specific table.
          abstract def remove_unique_constraint(
            table : TableState,
            unique_constraint : Management::Constraint::Unique
          ) : Nil

          # Renames a specific column.
          abstract def rename_column(table : TableState, column : Column::Base, new_name : String)

          # Renames a specific table.
          abstract def rename_table(table : TableState, new_name : String) : Nil

          # Deletes the table corresponding to a specific table state.
          def delete_table(table : TableState) : Nil
            delete_table(table.name)
          end

          # Flushes all model tables.
          def flush_model_tables : Nil
            tables_to_flush = Introspector.for(@connection).model_table_names.map { |n| quote(n) }
            return if tables_to_flush.empty?

            flush_tables(tables_to_flush)
          end

          # Syncs all models for the current database connection.
          #
          # Every model whose table is not yet created will be created at the database level. This method should not be
          # used on production databases (those are likely to be mutated using migrations), but this can be usefull when
          # initializing a database for the first time in development or when running tests.
          def sync_models : Nil
            table_names = Introspector.for(@connection).table_names
            project_state = ProjectState.from_apps(Marten.apps.app_configs)
            project_state.tables.values.each do |table|
              next if table_names.includes?(table.name)
              create_table(table)
            end
          end

          protected def execute(sql : String)
            @connection.open do |db|
              db.exec(sql)
            end
          end

          protected def execute_deferred_statements
            @deferred_statements.each do |sql|
              execute(sql.to_s)
            end
            @deferred_statements.clear
          end

          private delegate build_sql, to: @connection
          private delegate quote, to: @connection

          private def index_name(table_name, columns, suffix)
            index_name = "index_#{table_name}_on_#{columns.join("_")}#{suffix}"
            return index_name if index_name.size <= @connection.max_name_size

            digest = Digest::MD5.new
            digest.update(table_name)
            columns.each { |c| digest.update(c) }
            digest.update(suffix)

            index_suffix = (digest.final.hexstring[...8] + suffix)[...(@connection.max_name_size - 20)]
            remaining_size = @connection.max_name_size - 8 - index_suffix.size

            String.build do |s|
              s << "index_"

              table_columns = "#{table_name}_#{columns.join("_")}"[..remaining_size]
              s << table_columns
              s << "_" unless table_columns.ends_with?('_')

              s << index_suffix
            end
          end

          private def statement_columns(*args, **kwargs)
            Statement::Columns.new(->quote(String), *args, **kwargs)
          end

          private def statement_foreign_key_name(*args, **kwargs)
            Statement::ForeignKeyName.new(->index_name(String, Array(String), String), *args, **kwargs)
          end

          private def statement_index_name(*args, **kwargs)
            Statement::IndexName.new(->index_name(String, Array(String), String), *args, **kwargs)
          end

          private def statement_table(*args, **kwargs)
            Statement::Table.new(->quote(String), *args, **kwargs)
          end
        end
      end
    end
  end
end
