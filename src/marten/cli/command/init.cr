require "./init/**"

module Marten
  module CLI
    class Command
      class Init < Base
        help "Initialize a new Marten project or application structure."

        @@templates = [] of Template.class

        @dir : String?
        @name : String?
        @type : String?

        def self.templates
          @@templates
        end

        def setup
          on_argument(:type, "Type of structure to initialize: 'project' or 'app'") { |v| @type = v }
          on_argument(:name, "Name of the project to initialize") { |v| @name = v }
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

          self.class.templates.each do |template_klass|
            tpl = template_klass.new(context)
            print("  › Creating #{style(tpl.path, mode: :dim)}...", ending: "")
            tpl.render
            print(style(" DONE", fore: :light_green, mode: :bold))
          end
        end

        TEMPLATE_DIR = "#{__DIR__}/init/templates"

        macro template(template_path, destination_path)
          {% template_klass = template_path.split(".").map(&.capitalize).join("").id %}

          class {{ template_klass }} < Template
            ECR.def_to_s({{"#{TEMPLATE_DIR.id}/#{template_path.id}"}})

            def path
              {{ destination_path }}
            end
          end

          templates << {{ template_klass }}
        end

        template "config_routes.cr.ecr", "config/routes.cr"
        template "config_settings_base.cr.ecr", "config/settings/base.cr"
        template "config_settings_development.cr.ecr", "config/settings/development.cr"
        template "config_settings_production.cr.ecr", "config/settings/production.cr"

        template "spec_helper.cr.ecr", "spec/spec_helper.cr"

        template "src_project.cr.ecr", "src/project.cr"
        template "src_server.cr.ecr", "src/server.cr"

        template "manage.cr.ecr", "manage.cr"
      end
    end
  end
end
