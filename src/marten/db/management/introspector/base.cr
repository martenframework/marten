module Marten
  module DB
    module Management
      module Introspector
        abstract class Base
          def initialize(@connection : Connection::Base)
          end

          abstract def list_table_names_statement : String

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
