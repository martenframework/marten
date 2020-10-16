require "./migration/**"

module Marten
  module DB
    abstract class Migration
      include Apps::Association
      include DSL

      macro inherited
        def self.migration_name
          File.basename(__FILE__, ".cr")
        end

        Marten::DB::Management::Migrations.register({{ @type }})
      end

      @@app_config : Marten::Apps::Config?
      @@replacement_ids : Array(String)?

      class_getter atomic : Bool = true
      class_getter depends_on = [] of Tuple(String, String)
      class_getter replaces = [] of Tuple(String, String)

      @plan_loading_direction : Symbol?

      # Allows to specify whether the whole migration should run inside a single transaction or not.
      #
      # By default, for databases that support DDL transactions, each migration will run inside a single transaction.
      # This can be disabled on a per-migration basis, which can be useful is the migration is intended to affect large
      # tables or when performing data migrations.
      def self.atomic(atomic : Bool)
        @@atomic = atomic
      end

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

      def initialize
        @operations_bidirectional = [] of Operation::Base
        @operations_backward = [] of Operation::Base
        @operations_forward = [] of Operation::Base
        @plan_loaded = false
        @plan_loading_direction = nil
      end

      def apply_backward(
        project_state : Management::Migrations::ProjectState,
        schema_editor : Management::SchemaEditor::Base
      )
        operations_backward.not_nil!.each do |operation|
          old_state = project_state.clone
          operation.mutate_state_backward(self.class.app_config.label, project_state)
          operation.mutate_db_backward(self.class.app_config.label, schema_editor, old_state, project_state)
        end

        project_state
      end

      def apply_forward(
        project_state : Management::Migrations::ProjectState,
        schema_editor : Management::SchemaEditor::Base
      )
        operations_forward.not_nil!.each do |operation|
          old_state = project_state.clone
          operation.mutate_state_forward(self.class.app_config.label, project_state)
          operation.mutate_db_forward(self.class.app_config.label, schema_editor, old_state, project_state)
        end

        project_state
      end

      def atomic?
        self.class.atomic
      end

      def id
        self.class.id
      end

      def mutate_state_forward(project_state : Management::Migrations::ProjectState, preserve = true)
        new_state = preserve ? project_state.clone : project_state
        operations_forward.not_nil!.each do |operation|
          operation.mutate_state_forward(self.class.app_config.label, new_state)
        end

        new_state
      end

      def operations_backward
        load_plan unless plan_loaded?
        @operations_backward.empty? ? @operations_bidirectional.reverse : @operations_backward
      end

      def operations_forward
        load_plan unless plan_loaded?
        @operations_forward.empty? ? @operations_bidirectional : @operations_forward
      end

      def plan
      end

      def plan_backward
      end

      def plan_forward
      end

      private def operations
        case @plan_loading_direction
        when :bidirectional
          @operations_bidirectional
        when :backward
          @operations_backward
        when :forward
          @operations_forward
        end.not_nil!
      end

      private def load_plan
        @plan_loading_direction = :bidirectional
        plan

        @plan_loading_direction = :backward
        plan_backward

        @plan_loading_direction = :forward
        plan_forward

        @plan_loaded = true
      end

      private def plan_loaded?
        @plan_loaded
      end
    end
  end
end
