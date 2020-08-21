module Marten
  module DB
    module Management
      module Introspector
        def self.for(connection : Connection::Base)
          case connection
          when Connection::PostgreSQL
            klass = PostgreSQL
          when Connection::SQLite
            klass = SQLite
          end

          klass.not_nil!.new(connection)
        end
      end
    end
  end
end
