require "./model/**"

module Marten
  module CLI
    abstract class Generator
      # Allows to generate models.
      class Model < Generator
        help "Generate a model."

        @app_label : String? = nil
        @model_arguments = [] of String
        @model_name = ""
        @no_timestamps = false
        @parent : String? = nil

        def setup
          command.on_argument(:name, "Name of the model to generate") { |v| @model_name = v }
          command.on_unknown_argument { |v| @model_arguments << v }

          command.on_option_with_arg(
            :app,
            arg: "app",
            description: "Target app where the model should be created"
          ) do |v|
            @app_label = v
          end

          command.on_option_with_arg(
            :parent,
            arg: "parent",
            description: "Parent class name for the generated model"
          ) do |v|
            @parent = v
          end

          command.on_option("no-timestamps", "Do not include timestamp fields in the generated model") do
            @no_timestamps = true
          end
        end

        def run : Nil
          # Fetch the specified app or default to the main one.
          app_config = (l = app_label).nil? ? Marten.apps.default : Marten.apps.get(l)

          # Validate the model name.
          if model_name.empty?
            command.print_error_and_exit("A model name must be specified")
          elsif !model_name.matches?(/^[A-Z]/)
            command.print_error_and_exit("The model name must be CamelCase")
          end

          # Extract field definitions.
          begin
            field_definitions = @model_arguments.map { |a| FieldDefinition.from_argument(a) }
          rescue error : ArgumentError
            command.print_error_and_exit(error.message)
          end

          # Generate the model.
          print_generation_message(app_config, model_name)
          context = Context.new(
            app_config: app_config,
            name: model_name,
            field_definitions: field_definitions,
            no_timestamps: no_timestamps?,
            parent: parent,
          )
          create_app_files(app_config, Templates.app_files(context))
        rescue error : Apps::Errors::AppNotFound
          command.print_error_and_exit(error.message)
        end

        private getter app_label
        private getter model_name
        private getter parent

        private getter? no_timestamps

        private def print_generation_message(app_config, model_name)
          if app_config.main?
            command.print("Generating model #{command.style(model_name, mode: :bold)}...\n\n")
          else
            command.print(
              "Generating model #{command.style(model_name, mode: :bold)} in app " \
              "#{command.style(app_config.label, mode: :bold)}...\n\n")
          end
        end
      end
    end
  end
end
