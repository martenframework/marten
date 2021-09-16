module Marten
  module CLI
    class Manage
      module Command
        class ListMigrations < Base
          command_name :listmigrations
          help "List all database migrations."

          @app_label : String?
          @db : String?

          def setup
            on_argument(:app_label, "The name of an application to list migrations for") { |v| @app_label = v }

            on_option_with_arg(
              :db,
              arg: "alias",
              description: "Specify the alias of the database on which migrations will be applied or unapplied " \
                           "(default to \"default\")"
            ) do |v|
              @db = v
            end
          end

          def run
            app_config = @app_label.nil? ? nil : Marten.apps.get(@app_label.not_nil!)

            reader = Marten::DB::Management::Migrations::Reader.new(
              Marten::DB::Connection.get(db || Marten::DB::Connection::DEFAULT_CONNECTION_NAME)
            )

            list_migrations(reader, app_config.nil? ? reader.apps_with_migrations : [app_config.not_nil!])
          rescue e : Apps::Errors::AppNotFound
            print_error(e.message)
          end

          private getter db

          private def list_migrations(reader, app_configs)
            if app_configs.empty?
              print("No migrations")
              return
            end

            app_configs.each do |app_config|
              print(style("[#{app_config.label}]", fore: :green))

              displayed_migrations = Set(DB::Migration).new
              app_leaves = reader.graph.leaves.select { |n| n.migration.class.app_config == app_config }

              app_leaves.each do |leaf_node|
                reader.graph.path_forward(leaf_node).each do |node|
                  if displayed_migrations.includes?(node.migration) || node.migration.class.app_config != app_config
                    next
                  end

                  applied_migration = reader.applied_migrations[node.migration.id]?
                  if applied_migration.nil?
                    print("  [ ] #{node.migration.id}")
                  else
                    print("  [✔] #{node.migration.id}")
                  end

                  displayed_migrations << node.migration
                end
              end

              if displayed_migrations.empty?
                print("  No migrations")
              end
            end
          end
        end
      end
    end
  end
end
