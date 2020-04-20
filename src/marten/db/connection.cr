module Marten
  module DB
    module Connection
      IMPLEMENTATIONS = {
        "sqlite" => SQLite,
      }

      @@registry = {} of ::String => Base

      def self.register(db_config : Conf::GlobalSettings::Database)
        @@registry[db_config.id] = IMPLEMENTATIONS[db_config.backend.to_s].new(db_config)
      end

      def self.registry
        @@registry
      end
    end
  end
end
