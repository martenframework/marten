require "./migration/**"

module Marten
  module DB
    abstract class Migration
      macro inherited
        # :nodoc:
        def self.dir_location
          __DIR__
        end

        def self.migration_name
          File.basename(__FILE__, ".cr")
        end

        Marten::DB::Management::Migrations.register({{ @type }})
      end

      @@app_config : Marten::Apps::Config?

      class_getter depends_on = [] of Tuple(String, String)
      class_getter replaces = [] of Tuple(String, String)

      # Allows to specify the dependencies of the current migration.
      #
      # This class method takes an `app_name` and a `migration_name` as argument and adds the corresponding migration
      # to the list of migration dependencies of the current migration.
      def self.depends_on(app_name : String | Symbol, migration_name : String | Symbol)
        @@depends_on << {app_name.to_s, migration_name.to_s}
      end

      # :nodoc:
      def self.dir_location
        __DIR__
      end

      def self.id
        gen_id(app_config.label, migration_name)
      end

      def self.migration_name
        "__base__migration"
      end

      # Allows to specify the migrations the current migration is replacing.
      #
      # This class method takes an `app_name` and a `migration_name` as argument and adds the corresponding migration
      # to the list of migration replaced by the current migration.
      def self.replaces(app_name : String | Symbol, migration_name : String | Symbol)
        @@replaces << {app_name.to_s, migration_name.to_s}
      end

      protected def self.app_config
        @@app_config ||= Marten.apps.get_containing(self)
      end

      protected def self.gen_id(app_label, migration_name)
        "#{app_label}_#{migration_name}"
      end

      def id
        self.class.id
      end

      def operations
      end
    end
  end
end
