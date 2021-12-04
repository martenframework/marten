module Marten
  module CLI
    class Manage
      module Command
        class GenMigrations < Base
          command_name :genmigrations
          help "Generate new database migrations."

          @app_label : String?
          @create_empty : Bool = false

          def setup
            on_argument(:app_label, "The name of an application to generate migrations for") { |v| @app_label = v }
            on_option("empty", "Create an empty migration") { @create_empty = true }
          end

          def run
            app_config = app_label.nil? ? nil : Marten.apps.get(app_label.not_nil!)

            if create_empty?
              if app_config.nil?
                print("An application label must be specified when using --empty")
                return
              end

              changes = gen_empty_migration_changes(app_config.not_nil!)
            else
              diff = DB::Management::Migrations::Diff.new
              changes = app_config.nil? ? diff.detect : diff.detect([app_config])
            end

            if changes.empty?
              print("No changes detected")
              return
            end

            write_migrations(changes)
          rescue e : Apps::Errors::AppNotFound
            print_error(e.message)
          end

          private getter app_label

          private def create_empty?
            @create_empty
          end

          private def gen_empty_migration_changes(app_config)
            reader = DB::Management::Migrations::Reader.new
            latest_migration_klass = reader.latest_migration(app_config.not_nil!)

            dependencies = Array(Tuple(String, String)).new
            if !latest_migration_klass.nil?
              dependencies << {app_config.label, latest_migration_klass.not_nil!.migration_name}
            end

            {
              app_config.label => [
                DB::Management::Migrations::Diff::Migration.new(
                  app_label: app_config.label,
                  name: "#{Time.local.to_s("%Y%m%d%H%M%S")}1",
                  operations: Array(DB::Migration::Operation::Base).new,
                  dependencies: dependencies
                ),
              ],
            }
          end

          private def write_migrations(changes)
            changes.each do |app_label, migrations|
              print(style("Generating migrations for app '#{app_label}':", fore: :light_blue, mode: :bold))
              app_config = Marten.apps.get(app_label)
              migrations.each do |migration|
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
