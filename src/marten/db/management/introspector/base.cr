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

          # Returns the details of the columns of a specific table.
          abstract def columns_details(table_name : String) : Array(ColumnInfo)

          # Returns an array of all the foreign key constraints of a specific table and column.
          abstract def foreign_key_constraint_names(table_name : String, column_name : String) : Array(String)

          # Returns an array of all the index names for a specific table and column.
          abstract def index_names(table_name : String, column_name : String) : Array(String)

          # Returns an array of all the primary key constraints of a specific table and column.
          abstract def primary_key_constraint_names(table_name : String, column_name : String) : Array(String)

          # Returns all the tables names in the considered database.
          abstract def table_names : Array(String)

          # Returns an array of all the unique constraints for a specific table and column.
          abstract def unique_constraint_names(table_name : String, column_name : String) : Array(String)

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

          private delegate build_sql, to: @connection
          private delegate quote, to: @connection
        end
      end
    end
  end
end
