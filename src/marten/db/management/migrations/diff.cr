module Marten
  module DB
    module Management
      module Migrations
        # Represents a migrations diff.
        #
        # This class gives the ability to compute the changes needed to go from an initial project state to a target
        # state. This is mostly used to generate new migration files when changes have been made to existing models.
        class Diff
          # :nodoc:
          alias OperationDependency = Tuple(String, String, Symbol)

          # :nodoc:
          alias DetectedOperation = Tuple(DB::Migration::Operation::Base, Array(OperationDependency))

          @from_state : ProjectState
          @to_state : ProjectState
          @reader : Reader? = nil
          @detected_operations = {} of String => Array(DetectedOperation)

          def initialize
            @reader = Reader.new
            @from_state = @reader.not_nil!.graph.to_project_state
            @to_state = DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
          end

          def initialize(@from_state : DB::Management::ProjectState, @to_state : DB::Management::ProjectState)
          end

          def detect(apps : Array(Apps::Config)? = nil)
            detect_changes(apps)
          end

          private def detect_changes(apps)
            @detected_operations = {} of String => Array(DetectedOperation)

            from_tables = @from_state.tables.keys.to_set
            to_tables = @to_state.tables.keys.to_set
            renamed_tables = handle_and_identify_renamed_tables(from_tables, to_tables)

            kept_tables = from_tables & to_tables

            # Generate a set of columns that are present in the original state.
            from_columns = @from_state.tables.compact_map do |tid, t|
              next unless kept_tables.includes?(tid)
              t.columns.map { |c| {t.app_label, t.name, c.name} }
            end.flatten.to_set
            renamed_tables.keys.each do |tid|
              table = @to_state.get_table(tid)
              from_columns += table.columns.map { |c| {table.app_label, table.name, c.name} }.to_set
            end

            # Generate a set of columns that are present in the destination state.
            to_columns = @to_state.tables.compact_map do |tid, t|
              next unless kept_tables.includes?(tid)
              t.columns.map { |c| {t.app_label, t.name, c.name} }
            end.flatten.to_set

            # Generate table-level operations.
            handle_created_tables(from_tables, to_tables)

            # Identify altered constraints and indexes.
            unique_constraint_changes = identify_added_and_removed_unique_constraints(
              from_tables,
              to_tables,
              renamed_tables
            )

            # Generate column-level operations.
            handle_removed_columns(from_columns, to_columns)
            handle_added_columns(from_columns, to_columns)

            # Generate altered constraints and indexes operations.
            handle_removed_unique_constraints(unique_constraint_changes)
            handle_added_unique_constraints(unique_constraint_changes)

            changes = generate_migrations
            changes = select_changes_for_apps(changes, apps) if !apps.nil?

            changes
          end

          private def generate_migrations
            operations_count = @detected_operations.keys.reduce(0) do |acc, k|
              acc + @detected_operations[k].size
            end

            migrations_per_app = {} of String => Array(Migration)

            migrations_from_operations_subsets_allowed = false

            # The idea of the following algorithm is to loop over all the migration operations that were detected for
            # all the applications and to generate migrations from those. The algorithm processes operations and their
            # dependencies through two main passes:
            #
            # 1. First we iterate over all the operations of all the applications and we try to generate a migration for
            #    each application (containing all the detected operations for this application) if all the dependencies
            #    of the underlying operations are resolved (either because the dependencies are in the current
            #    application itself or because the dependencies point toward applications which already had their
            #    migrations generated). At this point we don't try to generate migrations from "subsets" of the app's
            #    detected set of operations.
            #
            # 2. Secondly, at least after one iteration over all the applications operations (or right after we identify
            #    that migrations can no longer be generated without using subsets of operations), we try to identify
            #    subsets of operations associated with applications that have their dependencies resolved and we use
            #    these subsets to generate migrations.
            #
            # The algorithm stops when no operations are remaining from the initial set of operations. If after a full
            # iteration over all the applications operations the number of detected operations doesn't decrease, it
            # means that dependencies cannot be resolved.
            while operations_count > 0
              @detected_operations.each do |app_label, operations|
                resolved_operations = [] of Tuple(DB::Migration::Operation::Base, Array(OperationDependency))
                resolved_dependencies = Set(Tuple(String, String)).new

                operations.dup.each do |operation, dependencies|
                  resolved_operation_dependencies = Set(Tuple(String, String)).new
                  deps_satisfied = true

                  dependencies.each do |dependency|
                    if dependency[0] != app_label
                      @detected_operations[dependency[0]].each do |other_operation, _|
                        next unless operation_depends_on_dependency?(other_operation, dependency)
                        deps_satisfied = false
                        break
                      end

                      break unless deps_satisfied

                      if migrations_per_app.includes?(dependency[0])
                        resolved_operation_dependencies << {dependency[0], migrations_per_app[dependency[0]].last.name}
                      elsif migrations_from_operations_subsets_allowed
                        # If the app the operation depends on is not considered in the set of detected operations, we
                        # use either the first or last migration of the application.

                        app_migrations = if !@reader.nil?
                                           @reader.not_nil!.graph.leaves.map(&.migration).select do |m|
                                             m.class.app_config.label == dependency[0]
                                           end
                                         end

                        resolved_operation_dependencies << if app_migrations.nil? || app_migrations.not_nil!.empty?
                          {dependency[0], "__first__"}
                        else
                          {dependency[0], app_migrations.not_nil!.first.class.migration_name}
                        end
                      else
                        deps_satisfied = false
                      end
                    end
                  end

                  if deps_satisfied
                    resolved_operations << {operation, dependencies}
                    resolved_dependencies.concat(resolved_operation_dependencies)
                    @detected_operations[app_label].shift
                  else
                    break
                  end
                end

                if resolved_dependencies || resolved_operations
                  if @detected_operations[app_label].empty? || migrations_from_operations_subsets_allowed
                    migrations_per_app[app_label] ||= [] of Migration
                    migrations_per_app[app_label] << Migration.new(
                      app_label: app_label,
                      name: Time.local.to_s("%Y%m%d%H%M%S") + (migrations_per_app[app_label].size + 1).to_s,
                      operations: resolved_operations.map { |o| o[0] },
                      dependencies: resolved_dependencies.to_a
                    )
                  else
                    @detected_operations[app_label] = resolved_operations + @detected_operations[app_label]
                  end
                end
              end

              new_operations_count = @detected_operations.keys.reduce(0) do |acc, k|
                acc + @detected_operations[k].size
              end

              if new_operations_count == operations_count
                if !migrations_from_operations_subsets_allowed
                  migrations_from_operations_subsets_allowed = true
                else
                  raise "Operation dependencies cannot be resolved!"
                end
              end

              operations_count = new_operations_count
            end

            # Add dependencies between migrations that are part of the application.
            migrations_per_app.each do |app_label, migrations|
              migrations.each_with_index do |migration, i|
                next_migration = migrations[i + 1]?
                next if next_migration.nil?
                next_migration.dependencies << {app_label, migration.name}
              end
            end

            # Loop over all the generated migrations and ensure the dependencies of the first migration for each app
            # are consistent with the latest existing migration of the same app if applicable.
            migrations_per_app.each do |app_label, migrations|
              next if migrations.empty?

              last_migration = if !@reader.nil?
                                 @reader.not_nil!.graph.leaves.map(&.migration).find do |m|
                                   m.class.app_config.label == app_label
                                 end
                               end

              next if last_migration.nil?

              migrations.first.dependencies << {app_label, last_migration.class.migration_name}
            end

            migrations_per_app
          end

          private def handle_added_columns(from_columns, to_columns)
            (to_columns - from_columns).each do |app_label, table_name, column_name|
              column = @to_state.get_table(app_label, table_name).get_column(column_name)
              dependencies = [] of OperationDependency

              if column.is_a?(Column::ForeignKey)
                related_table = @to_state.tables.values
                  .find { |t| t.name == column.as(Column::ForeignKey).to_table }
                  .not_nil!
                dependencies << OperationDependency.new(related_table.app_label, related_table.name, :created_table)
              end

              insert_operation(
                app_label,
                DB::Migration::Operation::AddColumn.new(table_name, column.dup),
                dependencies
              )
            end
          end

          private def handle_added_unique_constraints(unique_constraint_changes)
            unique_constraint_changes.each do |app_label, changes|
              changes[:added].each do |table_name, unique_constraint|
                insert_operation(
                  app_label,
                  DB::Migration::Operation::AddUniqueConstraint.new(table_name, unique_constraint.dup),
                  [] of OperationDependency
                )
              end
            end
          end

          private def handle_and_identify_renamed_tables(from_tables, to_tables)
            renamed_tables = {} of String => String

            (to_tables - from_tables).each do |created_table_id|
              created_table = @to_state.get_table(created_table_id)

              (from_tables - to_tables).each do |deleted_table_id|
                deleted_table = @from_state.get_table(deleted_table_id)
                next unless created_table.app_label == deleted_table.app_label
                next unless created_table.columns == deleted_table.columns

                dependencies = [] of OperationDependency

                # Extract dependencies for all the foreign key columns associated with the considered table.
                created_table.columns.select(Column::ForeignKey).each do |fk_column|
                  related_table = @to_state.tables.values
                    .find { |t| t.name == fk_column.as(Column::ForeignKey).to_table }
                    .not_nil!
                  dependencies << OperationDependency.new(related_table.app_label, related_table.name, :created_table)
                end

                insert_operation(
                  created_table.app_label,
                  DB::Migration::Operation::RenameTable.new(
                    deleted_table.name,
                    created_table.name,
                  ),
                  dependencies
                )

                from_tables.delete(deleted_table_id)
                from_tables.add(created_table_id)

                renamed_tables[created_table_id] = deleted_table_id
              end
            end

            renamed_tables
          end

          private def handle_created_tables(from_tables, to_tables)
            (to_tables - from_tables).each do |created_table_id|
              created_table = @to_state.get_table(created_table_id)

              dependencies = [] of OperationDependency

              # Extract dependencies for all the foreign key columns associated with the considered table.
              created_table.columns.select(Column::ForeignKey).each do |fk_column|
                related_table = @to_state.tables.values
                  .find { |t| t.name == fk_column.as(Column::ForeignKey).to_table }
                  .not_nil!
                dependencies << OperationDependency.new(related_table.app_label, related_table.name, :created_table)
              end

              insert_operation(
                created_table.app_label,
                DB::Migration::Operation::CreateTable.new(
                  created_table.name,
                  created_table.columns.dup,
                  created_table.unique_constraints.dup
                ),
                dependencies,
                beginning: true
              )
            end
          end

          private def handle_removed_columns(from_columns, to_columns)
            (from_columns - to_columns).each do |app_label, table_name, column_name|
              insert_operation(
                app_label,
                DB::Migration::Operation::RemoveColumn.new(table_name, column_name),
                [] of OperationDependency
              )
            end
          end

          private def handle_removed_unique_constraints(unique_constraint_changes)
            unique_constraint_changes.each do |app_label, changes|
              changes[:removed].each do |table_name, unique_constraint|
                insert_operation(
                  app_label,
                  DB::Migration::Operation::RemoveUniqueConstraint.new(table_name, unique_constraint.name),
                  [] of OperationDependency
                )
              end
            end
          end

          private def identify_added_and_removed_unique_constraints(from_tables, to_tables, renamed_tables)
            changed_unique_constraints_per_app = {} of String => NamedTuple(
              added: Array(Tuple(String, Management::Constraint::Unique)),
              removed: Array(Tuple(String, Management::Constraint::Unique)))

            (from_tables & to_tables).each do |remaining_table_id|
              from_table_state = @from_state.get_table(renamed_tables.fetch(remaining_table_id, remaining_table_id))
              to_table_state = @to_state.get_table(remaining_table_id)

              from_unique_constraints = from_table_state.unique_constraints
              to_unique_constraints = to_table_state.unique_constraints

              added_constraints = to_unique_constraints.reject { |c| from_unique_constraints.includes?(c) }
              removed_constraints = from_unique_constraints.reject { |c| to_unique_constraints.includes?(c) }

              changed_unique_constraints_per_app[to_table_state.app_label] ||= {
                added:   [] of Tuple(String, Management::Constraint::Unique),
                removed: [] of Tuple(String, Management::Constraint::Unique),
              }

              changed_unique_constraints_per_app[to_table_state.app_label][:added].concat(
                added_constraints.map { |c| {to_table_state.name, c} }
              )
              changed_unique_constraints_per_app[to_table_state.app_label][:removed].concat(
                removed_constraints.map { |c| {to_table_state.name, c} }
              )
            end

            changed_unique_constraints_per_app
          end

          private def insert_operation(app_label, operation, dependencies, beginning = false)
            ops = (@detected_operations[app_label] ||= [] of DetectedOperation)
            beginning ? ops.unshift({operation, dependencies}) : ops.push({operation, dependencies})
          end

          private def operation_depends_on_dependency?(operation, dependency)
            case dependency[2]
            when :created_table
              operation.is_a?(DB::Migration::Operation::CreateTable) && operation.name == dependency[1]
            else
              false
            end
          end

          private def select_changes_for_apps(changes, apps)
            # Construct a hash where each app's dependencies are tracked. App dependencies correspond to all the app
            # labels that are dependencies of at least one of the app's migrations.
            app_dependencies = Hash(String, Set(String)).new
            changes.each do |app_label, migrations|
              migrations.each do |migration|
                migration.dependencies.each do |dependency_app_label, _|
                  app_dependencies[app_label] ||= Set(String).new
                  app_dependencies[app_label] << dependency_app_label
                end
              end
            end

            # Build a set of app labels whose migrations must be kept in the final changes: those includes the
            # migrations of the specified `apps` but also some associated app migrations possibly.
            required_apps = apps.map(&.label).to_set
            old_required_apps = Set(String)
            while old_required_apps != required_apps
              old_required_apps = required_apps.dup
              required_apps.each do |app_label|
                next unless app_dependencies.has_key?(app_label)
                required_apps += app_dependencies[app_label]
              end
            end

            # Keep only the changes targetted by the required apps.
            changes.reject! { |app_label, _| !required_apps.includes?(app_label) }

            changes
          end
        end
      end
    end
  end
end
