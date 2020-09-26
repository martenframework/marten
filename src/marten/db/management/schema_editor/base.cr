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

            model.fields.each do |field|
              column_type = column_sql_for_field(field)
              column_definitions << "#{@connection.quote(field.db_column)} #{column_type}"
            end

            sql = create_table_statement(@connection.quote(model.db_table), column_definitions.join(", "))

            @connection.open do |db|
              db.exec(sql)
            end

            # Processes indexes configured as part of specific fields using db_index and the corresponding SQL
            # statements to the array of deferred SQL statements.
            model.fields.each do |field|
              next if !field.db_index? || field.unique?

              @deferred_statements << create_index_statement(
                index_name(model.db_table, [field.db_column]),
                @connection.quote(model.db_table),
                [@connection.quote(field.db_column)]
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

          private def column_sql_for_field(field)
            sql = field.db_type(@connection)

            sql += field.null? ? " NULL" : " NOT NULL"

            if field.primary_key?
              sql += " PRIMARY KEY"
            elsif field.unique?
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
