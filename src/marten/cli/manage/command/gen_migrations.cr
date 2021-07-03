module Marten
  module CLI
    class Manage
      module Command
        class GenMigrations < Base
          command_name :genmigrations
          help "Generate new database migrations."

          @app_label : String?

          def setup
            on_argument(:app_label, "The name of an application to generate migrations for") { |v| @app_label = v }
          end

          def run
            app_config = @app_label.nil? ? nil : Marten.apps.get(@app_label.not_nil!)

            diff = DB::Management::Migrations::Diff.new
            changes = app_config.nil? ? diff.detect : diff.detect([app_config])

            if changes.empty?
              print("No changes detected")
              return
            end

            write_migrations(changes)
          rescue e : Apps::Errors::AppNotFound
            print_error(e.message)
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
