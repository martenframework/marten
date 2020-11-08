module Marten
  module DB
    module Management
      module Introspector
        abstract class Base
          delegate build_sql, to: @connection
          delegate quote, to: @connection

          def initialize(@connection : Connection::Base)
          end

          # Returns the SQL statement allowing to list the foreign key constraints for a specific table.
          abstract def get_foreign_key_constraint_names_statement(table_name : String, column_name : String) : String

          # Returns the SQL statement allowing to list all table names.
          abstract def list_table_names_statement : String

          # Returns an array of all the foreign key constraints of a specific table.
          def foreign_key_constraint_names(table_name : String, column_name : String) : Array(String)
            names = [] of String

            @connection.open do |db|
              db.query(get_foreign_key_constraint_names_statement(table_name, column_name)) do |rs|
                rs.each do
                  names << rs.read(String)
                end
              end
            end

            names
          end

          # Returns all the table names associated with models of the installed applications only.
          def model_table_names
            table_names = [] of String

            Marten.apps.app_configs.each do |app_config|
              app_config.models.each do |model|
                table_names << model.db_table
              end
            end

            table_names
          end

          # Returns all the tables names in the considered database.
          def table_names
            names = [] of String

            @connection.open do |db|
              db.query(list_table_names_statement) do |rs|
                rs.each do
                  names << rs.read(String)
                end
              end
            end

            names
          end
        end
      end
    end
  end
end
