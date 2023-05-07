module Marten
  module CLI
    class Manage
      module Command
        class ResetMigrations < Base
          command_name :resetmigrations
          help "Reset an existing set of migrations into a single one."

          @app_label : String?

          def setup
            on_argument(:app_label, "The name of an application to reset migrations for") { |v| @app_label = v }
          end

          def run
            if app_label.nil? || app_label.try(&.empty?)
              print_error("You must specify an app label")
              return
            end

            app_config = Marten.apps.get(app_label.not_nil!)

            from_state = DB::Management::ProjectState.from_apps(Marten.apps.app_configs - [app_config])
            to_state = DB::Management::ProjectState.from_apps(Marten.apps.app_configs)

            reader = DB::Management::Migrations::Reader.new
            diff = DB::Management::Migrations::Diff.new(from_state, to_state)
            changes = diff.detect([app_config])

            if changes.empty?
              print("No changes detected")
              return
            end

            replacements = Array(Tuple(String, String)).new

            latest_migration = reader.latest_migration(app_config)
            if !latest_migration.nil?
              reader.graph.path_forward(latest_migration.not_nil!.new).each do |node|
                next unless node.migration.class.app_config == app_config
                replacements << {app_config.label, node.migration.class.migration_name}
              end
            end

            write_migrations(changes, replacements)
          rescue e : Apps::Errors::AppNotFound | DB::Management::Migrations::Errors::MigrationNotFound
            print_error(e.message)
          end

          private getter app_label
          private getter migration_name

          private def write_migrations(changes, replacements)
            changes.each do |app_label, migrations|
              print(style("Generating migrations for app '#{app_label}':", fore: :light_blue, mode: :bold))
              app_config = Marten.apps.get(app_label)
              migrations.each do |migration|
                migration.replacements += replacements

                migration_filepath = app_config.migrations_path.join("#{migration.name}.cr")

                print(
                  "  › Creating [#{style(migration_filepath.to_s.gsub("#{Dir.current}/", ""), mode: :dim)}]...",
                  ending: ""
                )

                Dir.mkdir(app_config.migrations_path) unless Dir.exists?(app_config.migrations_path)
                File.write(app_config.migrations_path.join("#{migration.name}.cr"), migration.serialize)

                print(style(" DONE", fore: :light_green, mode: :bold))

                migration.operations.each do |op|
                  print("      ○ #{op.describe}")
                end
              end
            end
          end
        end
      end
    end
  end
end
