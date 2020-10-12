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

          def execute(app_config : Apps::Config? = nil, migration_name : String? = nil)
            execute { }
          end

          def execute(app_config : Apps::Config? = nil, migration_name : String? = nil, &block)
            # TODO: add support for faked migrations.
            targets = find_targets(app_config, migration_name)

            # Generates migration plans that define the order in which migrations have to be applied. The plan only
            # contains migrations that were not applied yet while the full plan contains all the migrations that would
            # be applied if we were considering a fresh database.
            plan = generate_plan(targets)
            full_plan = generate_plan(@reader.graph.leaves, full: true)

            forward = plan.all? { |_migration, backward| !backward }
            if forward
              execute_forward(plan, full_plan) { |progress| yield progress }
            else
              execute_backward(plan, full_plan) { |progress| yield progress }
            end
          end

          def execution_needed?(app_config : Apps::Config? = nil, migration_name : String? = nil) : Bool
            targets = find_targets(app_config, migration_name)
            !generate_plan(targets).empty?
          end

          private def execute_backward(plan, full_plan)
            migration_ids_to_unapply = plan.map { |m, _d| m.id }

            # Create a project state corresponding up to the already applied migrations only.
            state = ProjectState.new
            full_plan.map(&.first).each do |migration|
              next unless @reader.applied_migrations.has_key?(migration.id)
              migration.mutate_state(state, preserve: false)
            end

            full_plan.map(&.first).each do |migration|
              break if migration_ids_to_unapply.empty?
              next unless migration_ids_to_unapply.includes?(migration.id)

              yield Progress.new(ProgressType::MIGRATION_APPLY_BACKWARD_START, migration)

              state = migrate_backward(state, migration)
              migration_ids_to_unapply.delete(migration.id)

              yield Progress.new(ProgressType::MIGRATION_APPLY_BACKWARD_SUCCESS, migration)
            end
          end

          private def execute_forward(plan, full_plan)
            migration_ids_to_apply = plan.map { |m, _d| m.id }

            # Create a project state corresponding up to the already applied migrations only.
            state = ProjectState.new
            full_plan.map(&.first).each do |migration|
              next unless @reader.applied_migrations.has_key?(migration.id)
              migration.mutate_state(state, preserve: false)
            end

            full_plan.map(&.first).each do |migration|
              break if migration_ids_to_apply.empty?
              next unless migration_ids_to_apply.includes?(migration.id)

              yield Progress.new(ProgressType::MIGRATION_APPLY_FORWARD_START, migration)

              state = migrate_forward(state, migration)
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
              @reader.graph.leaves
            end
          end

          private def generate_plan(targets, full = false)
            plan = [] of Tuple(Migration, Bool)
            applied_migrations = full ? {} of String => Migration : @reader.applied_migrations.dup

            targets.each do |target|
              if target.is_a?(PreInitialNode)
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

          private def migrate_backward(state, migration)
            SchemaEditor.run_for(@connection, atomic: migration.atomic?) do |schema_editor|
              state = migration.apply_backward(state, schema_editor)
              unrecord_migration(migration)
            end

            state
          end

          private def migrate_forward(state, migration)
            SchemaEditor.run_for(@connection, atomic: migration.atomic?) do |schema_editor|
              state = migration.apply_forward(state, schema_editor)
              record_migration(migration)
            end

            state
          end

          private def record_migration(migration)
            if !migration.class.replaces.empty?
              migration.class.replaces.each do |app_label, name|
                @recorder.record(app_label, name)
              end
            else
              @recorder.record(migration)
            end
          end

          private def unrecord_migration(migration)
            if !migration.class.replaces.empty?
              migration.class.replaces.each do |app_label, name|
                @recorder.unrecord(app_label, name)
              end
            else
              @recorder.unrecord(migration)
            end
          end
        end
      end
    end
  end
end
