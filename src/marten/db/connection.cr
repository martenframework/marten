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

      # Returns the connection to use for the passed model.
      #
      # Configured database routers are consulted in order to determine which database alias should be used. The
      # `write` argument indicates whether the connection is intended for a write operation (`true`) or a read
      # operation (`false`). An optional model `instance` can be provided so that routers can take instance-level
      # hints into account (such as a sticky database alias).
      #
      # If no router provides an opinion, the default database connection is returned.
      def self.for(model : Model.class, *, write : Bool = false, instance : Model? = nil)
        hints = Router::Hints.new(instance: instance)
        db_alias = write ? Router.db_for_write(model, hints) : Router.db_for_read(model, hints)
        db_alias.nil? ? default : get(db_alias)
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
