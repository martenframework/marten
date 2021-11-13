require "./init/**"

module Marten
  module CLI
    class Manage
      module Command
        class Init < Base
          # :nodoc:
          TEMPLATE_DIR = "#{__DIR__}/init/templates"

          help "Initialize a new Marten project or application structure."

          @@app_templates = [] of Template.class
          @@project_templates = [] of Template.class

          @dir : String?
          @name : String?
          @type : String?

          class_getter app_templates
          class_getter project_templates

          def setup
            on_argument(:type, "Type of structure to initialize: 'project' or 'app'") { |v| @type = v }
            on_argument(:name, "Name of the project or app to initialize") { |v| @name = v }
            on_argument(:dir, "Optional destination directory") { |v| @dir = v }
          end

          def run
            if @type.nil? || @type.not_nil!.empty?
              print_error("You must specify a valid structure type ('project or 'app')")
              return
            elsif @type != "project" && @type != "app"
              print_error("Unrecognized structure type, you must use 'project or 'app'")
              return
            elsif @name.nil? || @name.not_nil!.empty?
              print_error("You must specify a project or application name")
              return
            end

            context = Context.new
            context.name = @name.not_nil!
            context.dir = (@dir.nil? || @dir.not_nil!.empty?) ? @name.not_nil! : @dir.not_nil!

            create_files(
              @type == "project" ? self.class.project_templates : self.class.app_templates,
              context
            )
          end

          macro template(template_path, destination_path, templates_store_var)
            {% template_klass = destination_path.split(".").map(&.capitalize).join("") %}
            {% template_klass = template_klass.split("/").map(&.capitalize).join("") %}
            {% template_klass = templates_store_var.stringify.capitalize + "_" + template_klass %}
            {% template_klass = template_klass.id %}

            # :nodoc:
            class {{ template_klass }} < Template
              ECR.def_to_s({{"#{TEMPLATE_DIR.id}/#{template_path.id}"}})

              def path
                {{ destination_path }}
              end
            end

            {{ templates_store_var }} << {{ template_klass }}
          end

          macro app_template(template_path, destination_path)
            template({{ template_path }}, {{ destination_path }}, app_templates)
          end

          macro project_template(template_path, destination_path)
            template({{ template_path }}, {{ destination_path }}, project_templates)
          end

          app_template "app/app.cr.ecr", "app.cr"
          app_template "app/cli.cr.ecr", "cli.cr"
          app_template "shared/.gitkeep", "views/.gitkeep"
          app_template "shared/.gitkeep", "migrations/.gitkeep"
          app_template "shared/.gitkeep", "models/.gitkeep"

          project_template "project/config/settings/base.cr.ecr", "config/settings/base.cr"
          project_template "project/config/settings/development.cr.ecr", "config/settings/development.cr"
          project_template "project/config/settings/production.cr.ecr", "config/settings/production.cr"
          project_template "project/config/settings/test.cr.ecr", "config/settings/test.cr"
          project_template "project/config/routes.cr.ecr", "config/routes.cr"
          project_template "project/spec/spec_helper.cr.ecr", "spec/spec_helper.cr"
          project_template "project/src/project.cr.ecr", "src/project.cr"
          project_template "project/src/server.cr.ecr", "src/server.cr"
          project_template "project/manage.cr.ecr", "manage.cr"
          project_template "project/shard.yml.ecr", "shard.yml"

          private def create_files(templates, context)
            templates.each do |template_klass|
              tpl = template_klass.new(context)
              print("  › Creating #{style(tpl.path, mode: :dim)}...", ending: "")
              tpl.render
              print(style(" DONE", fore: :light_green, mode: :bold))
            end
          end
        end
      end
    end
  end
end
