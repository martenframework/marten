module Marten
  module DB
    module Management
      module SchemaEditor
        # Base implementation of a database schema editor.
        #
        # The database schema editor is used in the context of DB management in order to perform operation on models:
        # create / delete models, add new fields, etc. It's heavily used by the migrations mechanism.
        abstract class Base
          delegate quote, to: @connection

          def initialize(@connection : Connection::Base)
            @deferred_statements = [] of String
          end

          # Returns the database type for a specific built-in column implementation.
          #
          # Note that this method is only used when handling column types of Marten built-in types as custom column
          # implementations must define a `#db_type` method.
          abstract def column_type_for_built_in_column(id)

          # Returns the database type suffix for a specific built-in column implementation.
          #
          # Note that this method is only used when handling column types of Marten built-in types.
          abstract def column_type_suffix_for_built_in_column(id)

          # Returns the SQL statement allowing to create a database index.
          abstract def create_index_statement(name : String, table_name : String, columns : Array(String)) : String

          # Returns the SQL statement allowing to create a database table.
          abstract def create_table_statement(table_name : String, column_definitions : String) : String

          # Returns a boolean indicating if the schema editor implementation supports rollbacking DDL statements.
          abstract def ddl_rollbackable? : Bool

          # Returns the SQL statement allowing to delete a database table.
          abstract def delete_table_statement(table_name : String) : String

          # Returns the SQL statements allowing to flush the passed database tables.
          abstract def flush_tables_statements(table_names : Array(String)) : Array(String)

          # Creates a new table directly from a model class.
          def create_model(model : Model.class) : Nil
            create_table(Migrations::TableState.from_model(model))
          end

          # Creates a new table from a migration table state.
          def create_table(table : Migrations::TableState) : Nil
            column_definitions = [] of String

            table.columns.each do |column|
              column_type = column_sql_for(column)
              column_definitions << "#{quote(column.name)} #{column_type}"
            end

            sql = create_table_statement(quote(table.name), column_definitions.join(", "))

            @connection.open do |db|
              db.exec(sql)
            end

            # Forwards indexes configured as part of specific columns and the corresponding SQL statements to the array
            # of deferred SQL statements.
            table.columns.each do |column|
              next if !column.index? || column.unique?

              @deferred_statements << create_index_statement(
                index_name(table.name, [column.name]),
                quote(table.name),
                [quote(column.name)]
              )
            end
          end

          # Deletes the table of a specific model.
          def delete_model(model : Model.class)
            delete_table(Migrations::TableState.from_model(model))
          end

          # Deletes the table corresponding to a migration table state.
          def delete_table(table : Migrations::TableState)
            sql = delete_table_statement(quote(table.name))
            @connection.open do |db|
              db.exec(sql)
            end
          end

          # Flushes all model tables.
          def flush_model_tables : Nil
            table_names = @connection.introspector.model_table_names.map { |n| quote(n) }
            flush_statements = flush_tables_statements(table_names)
            @connection.open do |db|
              flush_statements.each do |sql|
                db.exec(sql)
              end
            end
          end

          # Syncs all models for the current database connection.
          #
          # Every model whose table is not yet created will be created at the database level. This method should not be
          # used on production databases (those are likely to be mutated using migrations), but this can be usefull when
          # initializing a database for the first time in development or when running tests.
          def sync_models : Nil
            table_names = @connection.introspector.table_names
            Marten.apps.app_configs.each do |app|
              app.models.each do |model|
                next if table_names.includes?(model.db_table)
                create_model(model)
              end
            end
          end

          protected def execute_deferred_statements
            @deferred_statements.each do |sql|
              @connection.open do |db|
                db.exec(sql)
              end
            end
          end

          private def column_sql_for(column)
            sql = column.sql_type(@connection)
            suffix = column.sql_type_suffix(@connection)

            sql += column.null? ? " NULL" : " NOT NULL"

            if column.primary_key?
              sql += " PRIMARY KEY"
            elsif column.unique?
              sql += " UNIQUE"
            end

            sql += " #{suffix}" unless suffix.nil?

            sql
          end

          private def index_name(table_name, columns)
            "index_#{table_name}_on_#{columns.join("_")}"
          end
        end
      end
    end
  end
end
