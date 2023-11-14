require "./schema/**"

module Marten
  module CLI
    abstract class Generator
      # Allows to generate schemas.
      class Schema < Generator
        help "Generate a schema."

        footer_description(
          <<-FOOTER_DESCRIPTION
          Description:

            Generates a schema with the specified name and field definitions. The schema will be
            generated in the app specified by the --app option or in the main app if no app is
            specified.

            Field definitions can be specified using the following formats:

              name:type
              name:type:modifier:modifier

            Where `name` is the name of the field and `type` is the type of the field.

            `modifier` is an optional field modifier. Field modifiers are used to specify additional
            (but non-mandatory) field options. For example: `name:string:optional` will produce a
            string field whose `required` option is set to `false`.

          Examples:

            Generate a schema in the main app:

              $ marten gen schema ArticleSchema title:string body:string

            Generate a schema in the blog app:

              $ marten gen schema ArticleSchema title:string body:string --app admin

            Generate a schema with a parent class:

              $ marten gen schema ArticleSchema title:string body:string --parent BaseSchema
          FOOTER_DESCRIPTION
        )

        @app_label : String? = nil
        @schema_arguments = [] of String
        @schema_name = ""
        @no_timestamps = false
        @parent : String? = nil

        def setup
          command.on_argument(:name, "Name of the schema to generate") { |v| @schema_name = v }
          command.on_unknown_argument(:field_definitions, "Field definitions of the schema to generate") do |v|
            @schema_arguments << v
          end

          command.on_option_with_arg(
            :app,
            arg: "app",
            description: "Target app where the schema should be created"
          ) do |v|
            @app_label = v
          end

          command.on_option_with_arg(
            :parent,
            arg: "parent",
            description: "Parent class name for the generated schema"
          ) do |v|
            @parent = v
          end
        end

        def run : Nil
          # Fetch the specified app or default to the main one.
          app_config = (l = app_label).nil? ? Marten.apps.main : Marten.apps.get(l)

          # Validate the schema name.
          if schema_name.empty?
            command.print_error_and_exit("A schema name must be specified")
          elsif !schema_name.matches?(/^[A-Z]/)
            command.print_error_and_exit("The schema name must be CamelCase")
          end

          # Add the "Schema" suffix if missing, which is a best practice.
          unless schema_name.ends_with?("Schema")
            self.schema_name += "Schema"
          end

          # Extract field definitions.
          begin
            field_definitions = @schema_arguments.map { |a| FieldDefinition.from_argument(a) }
          rescue ex : ArgumentError
            command.print_error_and_exit(ex.message)
          end

          # Generate the schema.
          print_generation_message(app_config, schema_name)
          context = Context.new(
            app_config: app_config,
            name: schema_name,
            field_definitions: field_definitions,
            parent: parent,
          )
          create_app_files(app_config, Templates.app_files(context))
        rescue ex : Apps::Errors::AppNotFound
          command.print_error_and_exit(ex.message)
        end

        private getter app_label
        private getter schema_name
        private getter parent

        private getter? no_timestamps

        private setter schema_name

        private def print_generation_message(app_config, schema_name)
          if app_config.main?
            command.print("Generating schema #{command.style(schema_name, mode: :bold)}...\n\n")
          else
            command.print(
              "Generating schema #{command.style(schema_name, mode: :bold)} in app " \
              "#{command.style(app_config.label, mode: :bold)}...\n\n")
          end
        end
      end
    end
  end
end
