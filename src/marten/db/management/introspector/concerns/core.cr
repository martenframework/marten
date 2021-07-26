module Marten
  module DB
    module Management
      module Introspector
        # :nodoc:
        module Core
          def table_names : Array(String)
            list_table_names
          end

          private def list_table_names
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

          private def list_table_names_statement
            raise NotImplementedError.new("Should be implemented by subclasses")
          end
        end
      end
    end
  end
end
