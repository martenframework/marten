require "./migration/dsl"
require "./migration/dsl/**"
require "./migration/operation/base"
require "./migration/operation/**"

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

      class_getter depends_on = [] of Tuple(String, String)
      class_getter replaces = [] of Tuple(String, String)

      class_getter? atomic : Bool = true

      @faked_operations_registration : Bool = false
      @plan_loading_direction : Symbol?

      # :nodoc:
      def self.app_config
        @@app_config ||= Marten.apps.get_containing(self)
      end

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
        pre_forward_project_state : Management::ProjectState,
        project_state : Management::ProjectState,
        schema_editor : Management::SchemaEditor::Base
      )
        ops_backward, directed_forward = operations_backward

        if directed_forward
          # If 'explicit' backward operations are defined (using 'plan_backward'), then this means that those
          # operations have to be applied forward since the intent of what's described in 'plan_backward' (and the
          # order of what's defined in this method) prevails.
          ops_backward.not_nil!.each do |operation|
            old_state = project_state.clone
            operation.mutate_state_forward(self.class.app_config.label, project_state)
            next if operation.faked?
            operation.mutate_db_forward(self.class.app_config.label, schema_editor, old_state, project_state)
          end
        else
          # Computes the state that would be active before each of the migration operations if they were executed
          # forward. This is necessary because some specific backward operations need the knowledge of the pre-forward
          # project state in order to properly revert themselves in some cases.
          pre_forward_operation_states = [] of Tuple(Management::ProjectState, Management::ProjectState)
          new_state = pre_forward_project_state
          operations_forward[0].not_nil!.each do |operation|
            new_state = new_state.clone
            old_state = new_state.clone
            operation.mutate_state_forward(self.class.app_config.label, new_state)
            pre_forward_operation_states << {old_state, new_state}
          end

          # Now revert each of the defined operations in reverse order by using the previously computed states.
          ops_backward.not_nil!.each do |operation|
            to_state, from_state = pre_forward_operation_states.pop

            if !operation.faked?
              operation.mutate_db_backward(self.class.app_config.label, schema_editor, from_state, to_state)
            end

            project_state = to_state
          end
        end

        project_state
      end

      def apply_forward(
        project_state : Management::ProjectState,
        schema_editor : Management::SchemaEditor::Base
      )
        operations_forward[0].not_nil!.each do |operation|
          old_state = project_state.clone
          operation.mutate_state_forward(self.class.app_config.label, project_state)
          next if operation.faked?
          operation.mutate_db_forward(self.class.app_config.label, schema_editor, old_state, project_state)
        end

        project_state
      end

      def atomic?
        self.class.atomic?
      end

      def id
        self.class.id
      end

      def mutate_state_forward(project_state : Management::ProjectState, preserve = true)
        new_state = preserve ? project_state.clone : project_state
        operations_forward[0].not_nil!.each do |operation|
          operation.mutate_state_forward(self.class.app_config.label, new_state)
        end

        new_state
      end

      def plan
      end

      def apply
      end

      def unapply
      end

      protected def operations_backward
        load_plan unless plan_loaded?
        @operations_backward.empty? ? {@operations_bidirectional.reverse, false} : {@operations_backward, true}
      end

      protected def operations_forward
        load_plan unless plan_loaded?
        {@operations_forward.empty? ? @operations_bidirectional : @operations_forward, true}
      end

      private def faked_operations_registration?
        @faked_operations_registration
      end

      private def load_plan
        @plan_loading_direction = :bidirectional
        plan

        @plan_loading_direction = :backward
        unapply

        @plan_loading_direction = :forward
        apply

        @plan_loaded = true
      end

      private def plan_loaded?
        @plan_loaded
      end

      private def register_operation(operation) : Nil
        operations = case @plan_loading_direction
                     when :bidirectional
                       @operations_bidirectional
                     when :backward
                       @operations_backward
                     when :forward
                       @operations_forward
                     end.not_nil!

        operation.faked = faked_operations_registration?
        operations << operation
      end

      private def with_faked_operations_registration(&)
        previous_faked_operations_registration = faked_operations_registration?
        @faked_operations_registration = true
        yield
      ensure
        @faked_operations_registration = previous_faked_operations_registration.not_nil!
      end
    end
  end
end
