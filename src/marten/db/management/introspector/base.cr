module Marten
  module DB
    module Management
      module Introspector
        # Base implementation of a database introspector.
        #
        # The database introspector is used in the context of DB management in order to fetch operation regarding
        # existing tables such as table names, index / constraint names, etc.
        abstract class Base
          def initialize(@connection : Connection::Base)
          end

          # Returns an array of all the foreign key constraints of a specific table and column.
          abstract def foreign_key_constraint_names(table_name : String, column_name : String) : Array(String)

          # Returns an array of all the index names for a specific table and column.
          abstract def index_names(table_name : String, column_name : String) : Array(String)

          # Returns the SQL statement allowing to list all table names.
          abstract def list_table_names_statement : String

          # Returns an array of all the unique constraints for a specific table and column.
          abstract def unique_constraint_names(table_name : String, column_name : String) : Array(String)

          # Returns all the tables names in the considered database.
          abstract def table_names : Array(String)

          # Returns all the table names associated with models of the installed applications only.
          def model_table_names : Array(String)
            table_names = [] of String

            Marten.apps.app_configs.each do |app_config|
              app_config.models.each do |model|
                table_names << model.db_table
              end
            end

            table_names
          end

          protected def list_table_names
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

          protected def list_table_names_statement
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private delegate build_sql, to: @connection
          private delegate quote, to: @connection
        end
      end
    end
  end
end
