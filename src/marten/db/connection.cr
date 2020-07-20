module Marten
  module DB
    module Connection
      DEFAULT_CONNECTION_NAME = "default"

      IMPLEMENTATIONS = {
        "postgresql" => PostgreSQL,
        "sqlite" => SQLite,
      }

      @@registry = {} of ::String => Base

      def self.register(db_config : Conf::GlobalSettings::Database)
        @@registry[db_config.id] = IMPLEMENTATIONS[db_config.backend.to_s].new(db_config)
      end

      def self.registry
        @@registry
      end

      # Returns the connection to use for the passed `table_name`.
      def self.for(table_name)
        # TODO: implement mechanism like a database router allowing to pick a connection based on the table name.
        registry[DEFAULT_CONNECTION_NAME]
      end
    end
  end
end
