require "./migration/**"

module Marten
  module DB
    abstract class Migration
      macro inherited
        # :nodoc:
        def self.dir_location
          __DIR__
        end

        # :nodoc:
        def self.migration_name
          File.basename(__FILE__, ".cr")
        end

        Marten::DB::Management::Migrations.register({{ @type }})
      end

      @@app_config : Marten::Apps::Config?

      # :nodoc:
      def self.dir_location
        __DIR__
      end

      # :nodoc:
      def self.id
        "#{app_config.label}_#{migration_name}"
      end

      # :nodoc:
      def self.migration_name
        "__base__migration"
      end

      protected def self.app_config
        @@app_config ||= Marten.apps.get_containing(self)
      end

      def operations
      end
    end
  end
end
