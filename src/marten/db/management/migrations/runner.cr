module Marten
  module DB
    module Management
      module Migrations
        class Runner
          PRE_INITIAL_MIGRATION_ID = "zero"

          def initialize(@connection : Connection::Base)
            @reader = Reader.new(@connection)
            @recorder = Recorder.new(@connection)
          end

          # Executes the migrations up until the specified app config / migration name (if specified).
          #
          # If no app config / migration name is specified, the method executes all the non-applied migrations.
          def execute(app_config : Apps::Config? = nil, migration_name : String? = nil, fake = false)
            execute(app_config: app_config, migration_name: migration_name, fake: fake) { }
          end

          # Executes the migrations up until the specified app config / migration name (if specified).
          #
          # If no app config / migration name is specified, the method executes all the non-applied migrations.
          #
          # It should be noted that this method yields a `Marten::DB::Management::Migrations::Runner::Progress` object
          # at each execution of a migration (before and after).
          def execute(app_config : Apps::Config? = nil, migration_name : String? = nil, fake = false, &)
            targets = find_targets(app_config, migration_name)

            # Generates migration plans that define the order in which migrations have to be applied. The plan only
            # contains migrations that were not applied yet while the full plan contains all the migrations that would
            # be applied if we were considering a fresh database.
            plan = generate_plan(targets)
            full_plan = generate_plan(@reader.graph.leaves, full: true)

            forward = plan.all? { |_migration, backward| !backward }
            if forward
              execute_forward(plan, full_plan, fake) { |progress| yield progress }
            else
              execute_backward(plan, full_plan, fake) { |progress| yield progress }
            end

            mark_elligible_replacements_as_applied { |progress| yield progress }
          end

          # Returns `true` if the execution of the runner is needed for the specified app config and migration name.
          def execution_needed?(app_config : Apps::Config? = nil, migration_name : String? = nil) : Bool
            targets = find_targets(app_config, migration_name)
            !generate_plan(targets).empty?
          end

          # Returns the migration plan for the specified app config and migration name.
          #
          # This method returns an array of tuples containing (i) a migration to apply and (ii) a boolean indicating if
          # the migration should be applied in a backward way.
          def plan(app_config : Apps::Config? = nil, migration_name : String? = nil) : Array(Tuple(Migration, Bool))
            generate_plan(find_targets(app_config, migration_name))
          end

          private def execute_backward(plan, full_plan, fake, &)
            migration_ids_to_unapply = plan.map { |m, _d| m.id }

            # Generates a hash of pre-migration states: each state in this hash corresponds to the state that would be
            # active if we were to apply each migration forward.
            pre_forward_state = ProjectState.new
            pre_forward_migration_states = {} of String => ProjectState
            full_plan.map(&.first).each do |migration|
              break if migration_ids_to_unapply.empty?

              if migration_ids_to_unapply.includes?(migration.id)
                pre_forward_migration_states[migration.id] = pre_forward_state
                pre_forward_state = migration.mutate_state_forward(pre_forward_state, preserve: true)
                migration_ids_to_unapply.delete(migration.id)
              elsif @reader.applied_migrations.has_key?(migration.id)
                migration.mutate_state_forward(pre_forward_state, preserve: false)
              end
            end

            state = generate_current_project_state(full_plan)
            plan.map(&.first).each do |migration|
              yield Progress.new(ProgressType::MIGRATION_APPLY_BACKWARD_START, migration)

              state = migrate_backward(pre_forward_migration_states[migration.id], state, migration, fake)
              migration_ids_to_unapply.delete(migration.id)

              yield Progress.new(ProgressType::MIGRATION_APPLY_BACKWARD_SUCCESS, migration)
            end
          end

          private def execute_forward(plan, full_plan, fake, &)
            migration_ids_to_apply = plan.map { |m, _d| m.id }
            state = generate_current_project_state(full_plan)

            full_plan.map(&.first).each do |migration|
              break if migration_ids_to_apply.empty?
              next unless migration_ids_to_apply.includes?(migration.id)

              yield Progress.new(ProgressType::MIGRATION_APPLY_FORWARD_START, migration)

              state = migrate_forward(state, migration, fake)
              migration_ids_to_apply.delete(migration.id)

              yield Progress.new(ProgressType::MIGRATION_APPLY_FORWARD_SUCCESS, migration)
            end
          end

          private def find_targets(app_config, migration_name)
            if !app_config.nil? && migration_name.nil?
              @reader.graph.leaves.select { |n| n.migration.class.app_config == app_config }
            elsif !app_config.nil? && migration_name == PRE_INITIAL_MIGRATION_ID
              [PreInitialNode.new(app_config.label)]
            elsif !app_config.nil? && !migration_name.nil?
              migration_klass = @reader.get_migration(app_config, migration_name)
              [@reader.graph.find_node(migration_klass.id)]
            else
              @reader.graph.leaves.select { |n| Marten.apps.app_configs.includes?(n.migration.class.app_config) }
            end
          end

          private def generate_current_project_state(full_plan)
            # Create a project state corresponding up to the already applied migrations only.
            state = ProjectState.new
            full_plan.map(&.first).each do |migration|
              next unless @reader.applied_migrations.has_key?(migration.id)
              migration.mutate_state_forward(state, preserve: false)
            end
            state
          end

          private def generate_plan(targets, full = false)
            plan = [] of Tuple(Migration, Bool)
            applied_migrations = full ? {} of String => Migration : @reader.applied_migrations.dup

            targets.each do |target|
              if target.is_a?(PreInitialNode)
                # In this case all the migrations within the considered app will be unapplied (including the first or
                # initial one). So we need to add all its dependents to the migration plan.
                @reader.graph.roots.select { |n| n.migration.class.app_config.label == target.app_label }.each do |root|
                  @reader.graph.path_backward(root).each do |node|
                    next unless applied_migrations.has_key?(node.migration.id)
                    plan << {node.migration, true}
                    applied_migrations.delete(node.migration.id)
                  end
                end

                next
              end

              target = target.as(Graph::Node)

              if applied_migrations.has_key?(target.migration.id)
                # If the target is already applied, this means that we must unapply all its dependent migrations up to
                # the target itself for the target's specific app.
                children_nodes_to_unapply = target.children.select do |n|
                  n.migration.class.app_config == target.migration.class.app_config
                end

                # Iterates over each node and generates backward migration steps for the migrations that were already
                # applied.
                children_nodes_to_unapply.each do |children_node|
                  @reader.graph.path_backward(children_node).each do |node|
                    next unless applied_migrations.has_key?(node.migration.id)
                    plan << {node.migration, true}
                    applied_migrations.delete(node.migration.id)
                  end
                end
              else
                # Generates a path toward the target where each step corresponds to a migration to apply.
                @reader.graph.path_forward(target).each do |node|
                  next if applied_migrations.has_key?(node.migration.id)
                  plan << {node.migration, false}
                  applied_migrations[node.migration.id] = node.migration
                end
              end
            end

            plan
          end

          private def get_applied_migration_ids
            @recorder.applied_migrations.map do |migration|
              Migration.gen_id(migration.app, migration.name)
            end
          end

          def mark_elligible_replacements_as_applied(&)
            applied_migration_ids = get_applied_migration_ids

            @reader.replacements.each do |replacement_migration_id, replacement_migration|
              # Only records the fact that the replacement migration has been applied when all the migrations it
              # replaces were already applied AND only if the replacement migration itself wasn't already recorded.
              next unless replacement_migration.class.replacement_ids.all? { |id| applied_migration_ids.includes?(id) }
              next if applied_migration_ids.includes?(replacement_migration_id)

              yield Progress.new(ProgressType::MIGRATION_APPLY_FORWARD_START, replacement_migration)

              @recorder.record(replacement_migration)

              yield Progress.new(ProgressType::MIGRATION_APPLY_FORWARD_SUCCESS, replacement_migration)
            end
          end

          private def migrate_backward(pre_forward_state, state, migration, fake)
            if fake
              unrecord_migration(migration)
            else
              SchemaEditor.run_for(@connection, atomic: migration.atomic?) do |schema_editor|
                state = migration.apply_backward(pre_forward_state, state, schema_editor)
                unrecord_migration(migration)
              end
            end

            state
          end

          private def migrate_forward(state, migration, fake)
            if fake || replacement_migration_already_applied?(migration)
              record_migration(migration)
            else
              SchemaEditor.run_for(@connection, atomic: migration.atomic?) do |schema_editor|
                state = migration.apply_forward(state, schema_editor)
                record_migration(migration)
              end
            end

            state
          end

          private def record_migration(migration)
            if !migration.class.replaces.empty?
              migration.class.replaces.each do |app_label, name|
                @recorder.record(app_label, name)
              end
            end

            @recorder.record(migration)
          end

          private def replacement_migration_already_applied?(migration)
            (
              !migration.class.replacement_ids.empty? &&
                migration.class.replacement_ids.all? { |id| get_applied_migration_ids.includes?(id) }
            )
          end

          private def unrecord_migration(migration)
            if !migration.class.replaces.empty?
              migration.class.replaces.each do |app_label, name|
                @recorder.unrecord(app_label, name)
              end
            end

            @recorder.unrecord(migration)
          end
        end
      end
    end
  end
end
