require "./migration/**"

module Marten
  module DB
    abstract class Migration
      include Apps::Association

      macro inherited
        def self.migration_name
          File.basename(__FILE__, ".cr")
        end

        Marten::DB::Management::Migrations.register({{ @type }})
      end

      @@app_config : Marten::Apps::Config?
      @@replacement_ids : Array(String)?

      class_getter depends_on = [] of Tuple(String, String)
      class_getter replaces = [] of Tuple(String, String)

      # Allows to specify the dependencies of the current migration.
      #
      # This class method takes an `app_name` and a `migration_name` as argument and adds the corresponding migration
      # to the list of migration dependencies of the current migration.
      def self.depends_on(app_name : String | Symbol, migration_name : String | Symbol)
        @@depends_on << {app_name.to_s, migration_name.to_s}
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

      def self.replacement_ids
        @@replacement_ids ||= @@replaces.map { |app_label, migration_name| gen_id(app_label, migration_name) }
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

      def mutate_state(project_state : Management::Migrations::ProjectState, preserve = true)
        new_state = preserve ? project_state : project_state.clone
        operations.not_nil!.each do |operation|
          operation.state_forward(self.class.app_config.label, new_state)
        end
        new_state
      end

      def operations
      end
    end
  end
end
