module Marten
  module CLI
    class Manage
      module Command
        class Migrate < Base
          help "Run database migrations."

          @app_label : String?
          @db : String?
          @fake : Bool = false
          @migration : String?
          @plan : Bool = false

          def setup
            on_argument(:app_label, "The name of an application to run migrations for") { |v| @app_label = v }

            on_argument(
              :migration,
              "A migration target (name or version) up to which the DB should be migrated. " \
              "Use 'zero' to unapply all the migrations of a specific application"
            ) do |v|
              @migration = v
            end

            on_option(:fake, "Set migrations as applied or unapplied without running them") { @fake = true }

            on_option(
              :plan,
              "Provides a comprehensive overview of the operations that will be performed by the migrations."
            ) do
              @plan = true
            end

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
            migration_name = @migration

            runner = Marten::DB::Management::Migrations::Runner.new(
              Marten::DB::Connection.get(db || Marten::DB::Connection::DEFAULT_CONNECTION_NAME)
            )

            if !runner.execution_needed?(app_config, migration_name)
              print("No pending migrations to apply")
            elsif plan?
              show_planned_migrations(runner, app_config, migration_name)
            else
              run_migrations(runner, app_config, migration_name)
            end
          rescue e : Apps::Errors::AppNotFound | DB::Management::Migrations::Errors::MigrationNotFound
            print_error(e.message)
          end

          private getter db

          private getter? fake
          private getter? plan

          private def process_execution_progress(progress)
            case progress.type
            when Marten::DB::Management::Migrations::Runner::ProgressType::MIGRATION_APPLY_BACKWARD_START
              print("  › Unapplying #{style(progress.migration.not_nil!.id, mode: :dim)}...", ending: "")
            when Marten::DB::Management::Migrations::Runner::ProgressType::MIGRATION_APPLY_BACKWARD_SUCCESS
              print(style(@fake ? " FAKED" : " DONE", fore: :light_green, mode: :bold))
            when Marten::DB::Management::Migrations::Runner::ProgressType::MIGRATION_APPLY_FORWARD_START
              print("  › Applying #{style(progress.migration.not_nil!.id, mode: :dim)}...", ending: "")
            when Marten::DB::Management::Migrations::Runner::ProgressType::MIGRATION_APPLY_FORWARD_SUCCESS
              print(style(@fake ? " FAKED" : " DONE", fore: :light_green, mode: :bold))
            end
          end

          private def run_migrations(runner, app_config, migration_name)
            print(style("Running migrations:", fore: :light_blue, mode: :bold), ending: "\n")

            runner.execute(app_config, migration_name, fake?) do |progress|
              process_execution_progress(progress)
            end
          end

          private def show_planned_migrations(runner, app_config, migration_name)
            print(style("Planned operations:", fore: :light_blue, mode: :bold), ending: "\n")

            runner.plan(app_config, migration_name).each do |migration, backward|
              print("  › For #{style(migration.id, mode: :dim)}:")

              (backward ? migration.operations_backward : migration.operations_forward).first.each do |operation|
                print("      ○ #{backward ? "Undo " : ""}#{operation.describe}")
              end
            end
          end
        end
      end
    end
  end
end
