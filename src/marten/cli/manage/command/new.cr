require "./new/**"

module Marten
  module CLI
    class Manage
      module Command
        class New < Base
          # :nodoc:
          TEMPLATE_DIR = "#{__DIR__}/new/templates"

          # :nodoc:
          TPL_ = {} of Nil => Nil

          help "Initialize a new Marten project or application structure."

          @@app_templates = [] of Template.class
          @@project_templates = [] of Template.class

          @dir : String?
          @interactive_mode : Bool = false
          @name : String?
          @type : String?
          @with_auth : Bool = false

          class_getter app_templates
          class_getter project_templates

          def setup
            on_argument(:type, "Type of structure to initialize: 'project' or 'app'") { |v| @type = v }
            on_argument(:name, "Name of the project or app to initialize") { |v| @name = v }
            on_option_with_arg(:d, :dir, arg: "dir", description: "Optional destination directory") { |v| @dir = v }
            on_option(:"with-auth", "Adds authentication to newly created projects") { @with_auth = true }
          end

          def run
            setup_interactive_mode

            print_welcome_message if interactive_mode? && (type.nil? || project? || app?)
            ask_for_structure_type if type.nil? || type.not_nil!.empty?

            if !project? && !app?
              print_error(invalid_structure_type_error_message)
              return
            end

            ask_for_project_or_app_name if name.nil? || name.not_nil!.empty?
            if !name_valid?
              print_error(invalid_project_or_app_name_error_message)
              return
            end

            ask_for_auth_app_addition if interactive_mode? && project? && !with_auth?

            if app? && with_auth?
              print_error("--with-auth can only be used when creating new projects")
            end

            context = Context.new
            context.name = name.not_nil!
            context.dir = (@dir.nil? || @dir.not_nil!.empty?) ? name.not_nil! : @dir.not_nil!
            context.targets << Context::TARGET_AUTH if with_auth?

            create_files(
              project? ? self.class.project_templates : self.class.app_templates,
              context
            )
          end

          macro template(template_path, destination_path)
            {% templates_store_var = TPL_["current_var"] %}
            {% target = TPL_["current_target"] %}
            {% template_klass = destination_path.split(".").map(&.capitalize).join("") %}
            {% template_klass = template_klass.split("/").map(&.capitalize).join("") %}
            {% template_klass = templates_store_var.capitalize + "_" + template_klass %}
            {% template_klass = template_klass.id %}

            # :nodoc:
            class {{ template_klass }} < Template
              ECR.def_to_s({{"#{TEMPLATE_DIR.id}/#{template_path.id}"}})

              def path
                {{ destination_path }}
              end

              def target
                {{ target }}
              end
            end

            {{ templates_store_var.id }} << {{ template_klass }}
          end

          macro templates(kind, target = "general")
            {% if kind.id.stringify == "project" %}
              {% templates_store_var = "project_templates" %}
            {% else %}
             {% templates_store_var = "app_templates" %}
            {% end %}

            {% TPL_["current_var"] = templates_store_var %}
            {% TPL_["current_target"] = target.id.stringify %}

            {{ yield }}
          end

          templates :app do
            template "app/app.cr.ecr", "app.cr"
            template "app/cli.cr.ecr", "cli.cr"
            template "shared/.gitkeep.ecr", "emails/.gitkeep"
            template "shared/.gitkeep.ecr", "handlers/.gitkeep"
            template "shared/.gitkeep.ecr", "migrations/.gitkeep"
            template "shared/.gitkeep.ecr", "models/.gitkeep"
            template "shared/.gitkeep.ecr", "schemas/.gitkeep"
            template "shared/.gitkeep.ecr", "templates/.gitkeep"
          end

          templates :project do
            template "shared/.gitkeep.ecr", "config/initializers/.gitkeep"
            template "shared/.gitkeep.ecr", "config/initializers/.gitkeep"
            template "project/config/settings/base.cr.ecr", "config/settings/base.cr"
            template "project/config/settings/development.cr.ecr", "config/settings/development.cr"
            template "project/config/settings/production.cr.ecr", "config/settings/production.cr"
            template "project/config/settings/test.cr.ecr", "config/settings/test.cr"
            template "project/config/routes.cr.ecr", "config/routes.cr"
            template "project/spec/spec_helper.cr.ecr", "spec/spec_helper.cr"
            template "project/src/assets/css/app.css.ecr", "src/assets/css/app.css"
            template "project/src/cli.cr.ecr", "src/cli.cr"
            template "project/src/project.cr.ecr", "src/project.cr"
            template "project/src/server.cr.ecr", "src/server.cr"
            template "shared/.gitkeep.ecr", "src/emails/.gitkeep"
            template "shared/.gitkeep.ecr", "src/handlers/.gitkeep"
            template "shared/.gitkeep.ecr", "src/migrations/.gitkeep"
            template "shared/.gitkeep.ecr", "src/models/.gitkeep"
            template "shared/.gitkeep.ecr", "src/schemas/.gitkeep"
            template "project/src/templates/base.html.ecr", "src/templates/base.html"
            template "project/.editorconfig.ecr", ".editorconfig"
            template "project/.gitignore.ecr", ".gitignore"
            template "project/manage.cr.ecr", "manage.cr"
            template "project/shard.yml.ecr", "shard.yml"
          end

          templates :project, target: :auth do
            template "project/spec/auth/emails/password_reset_email_spec.cr.ecr", "spec/auth/emails/password_reset_email_spec.cr" # ameba:disable Layout/LineLength
            template "project/spec/auth/emails/spec_helper.cr.ecr", "spec/auth/emails/spec_helper.cr"
            template "project/spec/auth/handlers/concerns/require_anonymous_user_spec.cr.ecr", "spec/auth/handlers/concerns/require_anonymous_user_spec.cr" # ameba:disable Layout/LineLength
            template "project/spec/auth/handlers/concerns/require_signed_in_user_spec.cr.ecr", "spec/auth/handlers/concerns/require_signed_in_user_spec.cr" # ameba:disable Layout/LineLength
            template "project/spec/auth/handlers/concerns/spec_helper.cr.ecr", "spec/auth/handlers/concerns/spec_helper.cr"                                 # ameba:disable Layout/LineLength
            template "project/spec/auth/handlers/password_reset_confirm_handler_spec.cr.ecr", "spec/auth/handlers/password_reset_confirm_handler_spec.cr"   # ameba:disable Layout/LineLength
            template "project/spec/auth/handlers/password_reset_initiate_handler_spec.cr.ecr", "spec/auth/handlers/password_reset_initiate_handler_spec.cr" # ameba:disable Layout/LineLength
            template "project/spec/auth/handlers/profile_handler_spec.cr.ecr", "spec/auth/handlers/profile_handler_spec.cr"                                 # ameba:disable Layout/LineLength
            template "project/spec/auth/handlers/sign_in_handler_spec.cr.ecr", "spec/auth/handlers/sign_in_handler_spec.cr"                                 # ameba:disable Layout/LineLength
            template "project/spec/auth/handlers/sign_out_handler_spec.cr.ecr", "spec/auth/handlers/sign_out_handler_spec.cr"                               # ameba:disable Layout/LineLength
            template "project/spec/auth/handlers/sign_up_handler_spec.cr.ecr", "spec/auth/handlers/sign_up_handler_spec.cr"                                 # ameba:disable Layout/LineLength
            template "project/spec/auth/handlers/spec_helper.cr.ecr", "spec/auth/handlers/spec_helper.cr"
            template "project/spec/auth/spec_helper.cr.ecr", "spec/auth/spec_helper.cr"
            template "project/spec/auth/schemas/password_reset_confirm_schema_spec.cr.ecr", "spec/auth/schemas/password_reset_confirm_schema_spec.cr"   # ameba:disable Layout/LineLength
            template "project/spec/auth/schemas/password_reset_initiate_schema_spec.cr.ecr", "spec/auth/schemas/password_reset_initiate_schema_spec.cr" # ameba:disable Layout/LineLength
            template "project/spec/auth/schemas/sign_in_schema_spec.cr.ecr", "spec/auth/schemas/sign_in_schema_spec.cr"
            template "project/spec/auth/schemas/sign_up_schema_spec.cr.ecr", "spec/auth/schemas/sign_up_schema_spec.cr"
            template "project/spec/auth/schemas/spec_helper.cr.ecr", "spec/auth/schemas/spec_helper.cr"
            template "project/src/auth/emails/password_reset_email.cr.ecr", "src/auth/emails/password_reset_email.cr"
            template "project/src/auth/handlers/concerns/require_anonymous_user.cr.ecr", "src/auth/handlers/concerns/require_anonymous_user.cr" # ameba:disable Layout/LineLength
            template "project/src/auth/handlers/concerns/require_signed_in_user.cr.ecr", "src/auth/handlers/concerns/require_signed_in_user.cr" # ameba:disable Layout/LineLength
            template "project/src/auth/handlers/password_reset_confirm_handler.cr.ecr", "src/auth/handlers/password_reset_confirm_handler.cr"   # ameba:disable Layout/LineLength
            template "project/src/auth/handlers/password_reset_initiate_handler.cr.ecr", "src/auth/handlers/password_reset_initiate_handler.cr" # ameba:disable Layout/LineLength
            template "project/src/auth/handlers/profile_handler.cr.ecr", "src/auth/handlers/profile_handler.cr"
            template "project/src/auth/handlers/sign_in_handler.cr.ecr", "src/auth/handlers/sign_in_handler.cr"
            template "project/src/auth/handlers/sign_out_handler.cr.ecr", "src/auth/handlers/sign_out_handler.cr"
            template "project/src/auth/handlers/sign_up_handler.cr.ecr", "src/auth/handlers/sign_up_handler.cr"
            template "project/src/auth/migrations/0001_create_auth_user_table.cr.ecr", "src/auth/migrations/0001_create_auth_user_table.cr" # ameba:disable Layout/LineLength
            template "project/src/auth/models/user.cr.ecr", "src/auth/models/user.cr"
            template "project/src/auth/schemas/password_reset_confirm_schema.cr.ecr", "src/auth/schemas/password_reset_confirm_schema.cr"   # ameba:disable Layout/LineLength
            template "project/src/auth/schemas/password_reset_initiate_schema.cr.ecr", "src/auth/schemas/password_reset_initiate_schema.cr" # ameba:disable Layout/LineLength
            template "project/src/auth/schemas/sign_in_schema.cr.ecr", "src/auth/schemas/sign_in_schema.cr"
            template "project/src/auth/schemas/sign_up_schema.cr.ecr", "src/auth/schemas/sign_up_schema.cr"
            template "project/src/auth/templates/auth/emails/password_reset.html.ecr", "src/auth/templates/auth/emails/password_reset.html"     # ameba:disable Layout/LineLength
            template "project/src/auth/templates/auth/password_reset_confirm.html.ecr", "src/auth/templates/auth/password_reset_confirm.html"   # ameba:disable Layout/LineLength
            template "project/src/auth/templates/auth/password_reset_initiate.html.ecr", "src/auth/templates/auth/password_reset_initiate.html" # ameba:disable Layout/LineLength
            template "project/src/auth/templates/auth/profile.html.ecr", "src/auth/templates/auth/profile.html"
            template "project/src/auth/templates/auth/sign_in.html.ecr", "src/auth/templates/auth/sign_in.html"
            template "project/src/auth/templates/auth/sign_up.html.ecr", "src/auth/templates/auth/sign_up.html"
            template "project/src/auth/app.cr.ecr", "src/auth/app.cr"
            template "project/src/auth/cli.cr.ecr", "src/auth/cli.cr"
            template "project/src/auth/routes.cr.ecr", "src/auth/routes.cr"
          end

          private NAME_RE      = /^[-a-zA-Z0-9_]+$/
          private TYPE_APP     = "app"
          private TYPE_PROJECT = "project"

          private getter dir
          private getter name
          private getter type

          private getter? interactive_mode
          private getter? with_auth

          private def app? : Bool
            type == TYPE_APP
          end

          private def ask_for_auth_app_addition(show_explanation : Bool = true) : Nil
            if show_explanation
              print_explanation(
                "Marten allows the generation of new projects with a built-in 'auth' application that efficiently " \
                "handles basic user management requirements through email/password authentication."
              )
            end

            print(style("\nInclude authentication [yes/no]?", mode: :bold), ending: " ")

            unless %w(y yes n no).includes?(answer = stdin.gets.to_s.downcase)
              ask_for_auth_app_addition(show_explanation: false)
            end

            @with_auth = %w(y yes).includes?(answer)
          end

          private def ask_for_project_or_app_name(show_explanation : Bool = true) : Nil
            if show_explanation
              print_explanation(
                "How to name your #{project? ? "project" : "app"}? " \
                "#{project? ? "Project" : "App"} names can only contain letters, numbers, underscores, and dashes."
              )
            end

            print(style("\n#{project? ? "Project" : "App"} name:", mode: :bold), ending: " ")
            @name = stdin.gets.to_s.downcase.strip

            if !name_valid?
              print(invalid_project_or_app_name_error_message)
              ask_for_project_or_app_name(show_explanation: false)
            end
          end

          private def ask_for_structure_type(show_explanation : Bool = true) : Nil
            if show_explanation
              print_explanation(
                "Which type of structure should be created? A 'project' corresponds to an entire webapp. An 'app' " \
                "corresponds to a reusable component that can be shared across multiple projects."
              )
            end

            print(style("\nStructure type ('project or 'app'):", mode: :bold), ending: " ")
            @type = stdin.gets.to_s.downcase

            if !project? && !app?
              print(invalid_structure_type_error_message)
              ask_for_structure_type(show_explanation: false)
            end
          end

          private def create_files(templates, context)
            print("") if interactive_mode?

            templates.map(&.new(context)).sort_by!(&.path).each do |tpl|
              next unless context.targets.includes?(tpl.target)

              print("› Creating #{style(tpl.path, mode: :dim)}...", ending: "")
              tpl.render
              print(style(" DONE", fore: :light_green, mode: :bold))
            end
          end

          private def invalid_project_or_app_name_error_message : String
            "#{project? ? "Project" : "App"} name can only contain letters, numbers, underscores, and dashes."
          end

          private def invalid_structure_type_error_message : String
            "Unrecognized structure type, you must use 'project or 'app'."
          end

          private def name_valid? : Bool
            !@name.nil? && !@name.not_nil!.empty? && NAME_RE.matches?(@name.to_s)
          end

          private def print_explanation(explanation : String) : Nil
            print(style("\n#{explanation}", mode: :dim), ending: "")
          end

          private def print_welcome_message : Nil
            welcome_message = " Welcome to Marten #{Marten::VERSION}! "
            print(style(" " * welcome_message.size, mode: :bold, fore: :light_red, back: :white))
            print(style(welcome_message, mode: :bold, fore: :light_red, back: :white))
            print(style(" " * welcome_message.size, mode: :bold, fore: :light_red, back: :white))
          end

          private def project? : Bool
            type == TYPE_PROJECT
          end

          private def setup_interactive_mode : Bool
            @interactive_mode = (
              type.nil? ||
              type.not_nil!.empty? ||
              (!type.nil? && (name.nil? || name.not_nil!.empty?))
            )
          end
        end
      end
    end
  end
end
