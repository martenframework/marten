module Marten
  module DB
    module Management
      module SchemaEditor
        # Base implementation of a database schema editor.
        #
        # The database schema editor is used in the context of DB management in order to perform operation on models:
        # create / delete models, add new fields, etc. It's heavily used by the migrations mechanism.
        abstract class Base
          def initialize(@connection : Connection::Base)
            @deferred_statements = [] of String
          end

          # Returns the SQL statement allowing to create a database index.
          abstract def create_index_statement(name : String, table_name : String, columns : Array(String)) : String

          # Returns the SQL statement allowing to create a database table.
          abstract def create_table_statement(table_name : String, column_definitions : String) : String

          # Returns a boolean indicating if the schema editor implementation supports rollbacking DDL statements.
          abstract def ddl_rollbackable? : Bool

          # Returns the SQL statement allowing to delete a database table.
          abstract def delete_table_statement(table_name : String) : String

          def create_model(model : Model.class)
            column_definitions = [] of String

            columns = model.fields.map(&.to_column)

            columns.each do |column|
              column_type = column_sql_for(column)
              column_definitions << "#{@connection.quote(column.name)} #{column_type}"
            end

            sql = create_table_statement(@connection.quote(model.db_table), column_definitions.join(", "))

            @connection.open do |db|
              db.exec(sql)
            end

            # Forwards indexes configured as part of specific columns and the corresponding SQL statements to the array
            # of deferred SQL statements.
            columns.each do |column|
              next if !column.index? || column.unique?

              @deferred_statements << create_index_statement(
                index_name(model.db_table, [column.name]),
                @connection.quote(model.db_table),
                [@connection.quote(column.name)]
              )
            end
          end

          def delete_model(model : Model.class)
            sql = delete_table_statement(@connection.quote(model.db_table))
            @connection.open do |db|
              db.exec(sql)
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

            sql += column.null? ? " NULL" : " NOT NULL"

            if column.primary_key?
              sql += " PRIMARY KEY"
            elsif column.unique?
              sql += " UNIQUE"
            end

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
