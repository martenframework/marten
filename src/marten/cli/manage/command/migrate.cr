module Marten
  module CLI
    class Manage
      module Command
        class Migrate < Base
          help "Run database migrations."

          @app_label : String?
          @fake : Bool = false
          @migration : String?

          def setup
            on_argument(:app_label, "The name of an application to run migrations for") { |v| @app_label = v }
            on_argument(
              :migration,
              "A migration target (name or version) up to which the DB should be migrated. " \
              "Use 'zero' to unapply all the migrations of a specific application"
            ) { |v| @migration = v }
            on_option(:fake, "Set migrations as applied or unapplied without running them") { @fake = true }
          end

          def run
            app_config = @app_label.nil? ? nil : Marten.apps.get(@app_label.not_nil!)
            migration_name = @migration

            runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)

            if !runner.execution_needed?(app_config, migration_name)
              print("No pending migrations to apply")
              return
            end

            print(style("Running migrations:", fore: :light_blue, mode: :bold), ending: "\n")

            runner.execute(app_config, migration_name, @fake) do |progress|
              process_execution_progress(progress)
            end
          rescue e : Apps::Errors::AppNotFound | DB::Management::Migrations::Errors::MigrationNotFound
            print_error(e.message)
          end

          private def process_execution_progress(progress)
            case progress.type
            when Marten::DB::Management::Migrations::Runner::ProgressType::MIGRATION_APPLY_BACKWARD_START
              print("  › Unapplying #{progress.migration.not_nil!.id}...", ending: "")
            when Marten::DB::Management::Migrations::Runner::ProgressType::MIGRATION_APPLY_BACKWARD_SUCCESS
              print(style(@fake ? " FAKED" : " DONE", fore: :light_green, mode: :bold))
            when Marten::DB::Management::Migrations::Runner::ProgressType::MIGRATION_APPLY_FORWARD_START
              print("  › Applying #{progress.migration.not_nil!.id}...", ending: "")
            when Marten::DB::Management::Migrations::Runner::ProgressType::MIGRATION_APPLY_FORWARD_SUCCESS
              print(style(@fake ? " FAKED" : " DONE", fore: :light_green, mode: :bold))
            end
          end
        end
      end
    end
  end
end
