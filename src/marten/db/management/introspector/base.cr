module Marten
  module DB
    module Management
      module Introspector
        abstract class Base
          def initialize(@connection : Connection::Base)
          end

          abstract def list_table_names_statement : String

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
