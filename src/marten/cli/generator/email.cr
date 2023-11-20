require "./email/**"

module Marten
  module CLI
    abstract class Generator
      # Allows to generate emails.
      class Email < Generator
        help "Generate an email."

        @app_label : String? = nil
        @email_name = ""
        @parent : String? = nil

        def setup
          command.on_argument(:name, "Name of the email to generate (must be CamelCase)") do |v|
            @email_name = v
          end

          command.on_option_with_arg(
            :app,
            arg: "app",
            description: "Target app where the email should be created"
          ) do |v|
            @app_label = v
          end

          command.on_option_with_arg(
            :parent,
            arg: "parent",
            description: "Parent class name for the generated email"
          ) do |v|
            @parent = v
          end
        end

        def run : Nil
          # Fetch the specified app or default to the main one.
          app_config = (l = app_label).nil? ? Marten.apps.main : Marten.apps.get(l)

          # Validate the email name.
          if email_name.empty?
            command.print_error_and_exit("An email name must be specified")
          elsif !email_name.matches?(/^[A-Z]/)
            command.print_error_and_exit("The email name must be CamelCase")
          end

          # Add the "Email" suffix if missing, which is a best practice.
          unless email_name.ends_with?("Email")
            self.email_name += "Email"
          end

          # Generate the email.
          print_generation_message(app_config, email_name)
          context = Context.new(app_config, email_name, parent)
          create_app_files(app_config, Templates.app_files(context))
        rescue e : Apps::Errors::AppNotFound
          command.print_error_and_exit(e.message)
        end

        private getter app_label
        private getter email_name
        private getter parent

        private setter email_name

        private def print_generation_message(app_config, email_name)
          if app_config.main?
            command.print("Generating email #{command.style(email_name, mode: :bold)}...\n\n")
          else
            command.print(
              "Generating email #{command.style(email_name, mode: :bold)} in app " \
              "#{command.style(app_config.label, mode: :bold)}...\n\n")
          end
        end
      end
    end
  end
end
