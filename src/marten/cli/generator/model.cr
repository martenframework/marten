require "./model/**"

module Marten
  module CLI
    abstract class Generator
      # Allows to generate models.
      class Model < Generator
        help "Generate a model."

        footer_description(
          <<-FOOTER_DESCRIPTION
          Description:

            Generates a model with the specified name and field definitions. The model will be
            generated in the app specified by the --app option or in the main app if no app is
            specified.

            Field definitions can be specified using the following formats:

              name:type
              name:type{qualifier}
              name:type:modifier:modifier

            Where `name` is the name of the field and `type` is the type of the field.

            `qualifier` can be required depending on the considered field type; when this is the
            case, it corresponds to a mandatory field option. For example, `label:string{128}` will
            produce a string field whose `max_size` option is set to `128`. Another example:
            `author:many_to_one{User}` will produce a many-to-one field whose `to` option is set to
            target the `User` model.

            `modifier` is an optional field modifier. Field modifiers are used to specify additional
            (but non-mandatory) field options. For example: `name:string:uniq` will produce a string
            field whose `unique` option is set to `true`. Another example: `name:string:uniq:index`
            will produce a string field whose `unique` and `index` options are set to `true`.

          Examples:

            Generate a model in the main app:

              $ marten gen model User name:string email:string

            Generate a model in the admin app:

              $ marten gen model User name:string email:string --app admin

            Generate a model with a many-to-one reference:

              $ marten gen model Article label:string body:text author:many_to_one{User}

            Generate a model with a parent class:

              $ marten gen model Admin::User name:string email:string --parent User

            Generate a model without timestamps:

              $ marten gen model User name:string email:string --no-timestamps
          FOOTER_DESCRIPTION
        )

        @app_label : String? = nil
        @model_arguments = [] of String
        @model_name = ""
        @no_timestamps = false
        @parent : String? = nil

        def setup
          command.on_argument(:name, "Name of the model to generate") { |v| @model_name = v }
          command.on_unknown_argument(:field_definitions, "Field definitions of the model to generate") do |v|
            @model_arguments << v
          end

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
          app_config = (l = app_label).nil? ? Marten.apps.main : Marten.apps.get(l)

          # Validate the model name.
          if model_name.empty?
            command.print_error_and_exit("A model name must be specified")
          elsif !model_name.matches?(/^[A-Z]/)
            command.print_error_and_exit("The model name must be CamelCase")
          end

          # Extract field definitions.
          begin
            field_definitions = @model_arguments.map { |a| FieldDefinition.from_argument(a) }
          rescue ex : ArgumentError
            command.print_error_and_exit(ex.message)
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
        rescue ex : Apps::Errors::AppNotFound
          command.print_error_and_exit(ex.message)
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
