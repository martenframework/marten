module Marten
  module DB
    module Connection
      DEFAULT_CONNECTION_NAME = "default"

      IMPLEMENTATIONS = {
        "postgresql" => PostgreSQL,
        "sqlite"     => SQLite,
      }

      @@registry = {} of ::String => Base

      def self.register(db_config : Conf::GlobalSettings::Database)
        @@registry[db_config.id] = IMPLEMENTATIONS[db_config.backend.to_s].new(db_config)
      end

      # Returns the default database connection.
      def self.default
        get(DEFAULT_CONNECTION_NAME)
      end

      def self.get(db_alias)
        registry[db_alias]
      rescue KeyError
        raise Errors::UnknownConnection.new("Unknown database connection '#{db_alias}'")
      end

      # Returns the connection to use for the passed `table_name`.
      def self.for(table_name)
        # TODO: implement mechanism like a database router allowing to pick a connection based on the table name.
        default
      end

      private def self.registry
        @@registry
      end
    end
  end
end
