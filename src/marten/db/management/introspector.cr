require "./introspector/**"

module Marten
  module DB
    module Management
      module Introspector
        IMPLEMENTATIONS = {
          Connection::MYSQL_ID      => Introspector::MySQL,
          Connection::POSTGRESQL_ID => Introspector::PostgreSQL,
          Connection::SQLITE_ID     => Introspector::SQLite,
        }

        # Returns an introspector for the passed connection.
        def self.for(connection : Connection::Base) : Introspector::Base
          IMPLEMENTATIONS[connection.id].new(connection)
        end
      end
    end
  end
end
