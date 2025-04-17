require "./handler/**"

module Marten
  module CLI
    abstract class Generator
      # Allows to generate handlers.
      class Handler < Generator
        help "Generate a handler."

        @app_label : String? = nil
        @handler_name = ""
        @parent : String? = nil

        def setup
          command.on_argument(:name, "Name of the handler to generate (must be CamelCase)") do |v|
            @handler_name = v
          end

          command.on_option_with_arg(
            :app,
            arg: "app",
            description: "Target app where the handler should be created"
          ) do |v|
            @app_label = v
          end

          command.on_option_with_arg(
            :parent,
            arg: "parent",
            description: "Parent class name for the generated handler"
          ) do |v|
            @parent = v
          end
        end

        def run : Nil
          # Fetch the specified app or default to the main one.
          app_config = (l = app_label).nil? ? Marten.apps.main : Marten.apps.get(l)

          # Validate the handler name.
          if handler_name.empty?
            command.print_error_and_exit("A handler name must be specified")
          elsif !handler_name.matches?(/^[A-Z]/)
            command.print_error_and_exit("The handler name must be CamelCase")
          end

          # Add the "Handler" suffix if missing, which is a best practice.
          unless handler_name.ends_with?(NAME_SUFFIX)
            self.handler_name += NAME_SUFFIX
          end

          # Generate the handler.
          print_generation_message(app_config, handler_name)
          context = Context.new(app_config, handler_name, parent)
          create_app_files(app_config, Templates.app_files(context))
        rescue e : Apps::Errors::AppNotFound
          command.print_error_and_exit(e.message)
        end

        private NAME_SUFFIX = "Handler"

        private getter app_label
        private getter handler_name
        private getter parent

        private setter handler_name

        private def print_generation_message(app_config, handler_name)
          if app_config.main?
            command.print("Generating handler #{command.style(handler_name, mode: :bold)}...\n\n")
          else
            command.print(
              "Generating handler #{command.style(handler_name, mode: :bold)} in app " \
              "#{command.style(app_config.label, mode: :bold)}...\n\n")
          end
        end
      end
    end
  end
end
