module Marten
  module DB
    module Connection
      DEFAULT_CONNECTION_NAME = "default"

      MYSQL_ID      = "mysql"
      POSTGRESQL_ID = "postgresql"
      SQLITE_ID     = "sqlite"

      IMPLEMENTATIONS = {
        MYSQL_ID      => MySQL,
        POSTGRESQL_ID => PostgreSQL,
        SQLITE_ID     => SQLite,
      }

      @@registry = {} of ::String => Base

      def self.register(db_config : Conf::GlobalSettings::Database)
        @@registry[db_config.id] = IMPLEMENTATIONS[db_config.backend.to_s].new(db_config)
      end

      # Returns the default database connection.
      def self.default
        get(DEFAULT_CONNECTION_NAME)
      end

      # Returns the connection to use for the passed `table_name`.
      def self.for(table_name)
        # TODO: implement mechanism like a database router allowing to pick a connection based on the table name.
        default
      end

      # Returns the database connection configured for a given `db_alias`.
      #
      # If no database connection can be found, a `Marten::DB::Errors::UnknownConnection` exception is raised.
      def self.get(db_alias : String | Symbol)
        registry[db_alias.to_s]
      rescue KeyError
        raise Errors::UnknownConnection.new("Unknown database connection '#{db_alias}'")
      end

      def self.registry
        @@registry
      end
    end
  end
end
