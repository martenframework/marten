module Marten
  module CLI
    abstract class Generator
      # Allows to generate applications.
      class App < Generator
        help "Generate an application."

        @app_label = ""
        @path_prefix : String? = nil

        def setup
          command.on_argument(:label, label_argument_description) do |v|
            @app_label = v
          end
        end

        def run : Nil
          # Validate the application label.
          if app_label.empty?
            command.print_error_and_exit("An application label must be specified")
          end

          begin
            Apps::Config.validate_label(app_label)
          rescue ex : Marten::Apps::Errors::InvalidAppConfig
            command.print_error_and_exit("Invalid application label - #{ex.message}")
          end

          # Ensures that no other app with the same label already exists.
          existing_app = begin
            Marten.apps.get(app_label)
          rescue Marten::Apps::Errors::AppNotFound
            nil
          end

          if !existing_app.nil?
            command.print_error_and_exit("An application with the same label already exists")
          end

          # Generate the application.
          command.print("Generating app #{command.style(app_label, mode: :bold)}...\n\n")
          context = Templates::App::Context.new(app_label)
          generate_app(context)
        end

        private getter app_label

        private def add_application_cli_requirement(context)
          command.print("› Adding application CLI requirement...", ending: "")
          project_cr_file_path = Path.new(Marten.apps.main.class._marten_app_location).expand.join("cli.cr")

          if File.exists?(project_cr_file_path)
            File.open(project_cr_file_path, "a") do |f|
              if located_in_apps_folder?
                f.print(%{require "./apps/#{app_label}/cli"\n})
              else
                f.print(%{require "./#{app_label}/cli"\n})
              end
            end

            command.print(command.style(" DONE", fore: :light_green, mode: :bold))
          else
            command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
            self.warnings << "Could not add application requirement to cli.cr file (file not found)"
          end
        end

        private def add_application_requirement(context)
          command.print("› Adding application requirement...", ending: "")
          project_cr_file_path = Path.new(Marten.apps.main.class._marten_app_location).expand.join("project.cr")

          if File.exists?(project_cr_file_path)
            File.open(project_cr_file_path, "a") do |f|
              if located_in_apps_folder?
                f.print(%{require "./apps/#{app_label}/app"\n})
              else
                f.print(%{require "./#{app_label}/app"\n})
              end
            end

            command.print(command.style(" DONE", fore: :light_green, mode: :bold))
          else
            command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
            self.warnings << "Could not add application requirement to project.cr file (file not found)"
          end
        end

        private def add_application_to_installed_apps_setting(context)
          command.print("› Adding application to installed_apps setting...", ending: "")
          base_settings_file = Path.new(Marten.apps.main.class._marten_app_location)
            .expand
            .join("../config/settings/base.cr")

          if File.exists?(base_settings_file)
            content = File.read(base_settings_file)

            # Find and modify the installed_apps array definition
            modified_content = content.gsub(/\h+(config\.installed_apps\s*=\s*\[[^\]]*\])/) do |match|
              installed_app_names = match
                .match(/\[([\s\S]*?)\]/)
                .not_nil![1]
                .split(",")
                .map(&.strip)
                .reject(&.empty?)

              installed_app_names << context.app_class_name

              [
                "  config.installed_apps = [",
                installed_app_names.map { |item| "    #{item}" }.join(",\n"),
                "  ]",
              ].join("\n")
            end

            # If the content was modified, write it back to the file, otherwise generates a warning.
            if !modified_content.empty?
              File.open(base_settings_file, "w") do |f|
                f.rewind
                f.print(modified_content)
                f.truncate(f.pos)
              end

              command.print(command.style(" DONE", fore: :light_green, mode: :bold))
            else
              command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
              self.warnings << "Could not add application to installed_apps setting (setting not found)"
            end
          else
            command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
            self.warnings << "Could not add application to installed_apps setting (setting file not found)"
          end
        end

        private def add_route_to_main_routes_map(context)
          command.print("› Adding app route to main routes map...", ending: "")
          routes_file = Path.new(Marten.apps.main.class._marten_app_location)
            .expand
            .join("../config/routes.cr")

          if File.exists?(routes_file)
            content = File.read(routes_file)

            marten_draw_marker = "Marten.routes.draw do"

            if content.includes?(marten_draw_marker)
              start_index = content.index!(marten_draw_marker)
              insert_position = start_index + marten_draw_marker.size

              modified_content = content.insert(
                insert_position,
                "\n  " + %{path "/#{context.label}", #{context.module_name}::ROUTES, name: "#{context.label}"}
              )

              File.open(routes_file, "w") do |f|
                f.rewind
                f.print(modified_content)
                f.truncate(f.pos)
              end

              command.print(command.style(" DONE", fore: :light_green, mode: :bold))
            else
              command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
              self.warnings << "Could not add app route to main routes map (no routes map block found)"
            end
          else
            command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
            self.warnings << "Could not add app route to main routes map (no config/routes.cr file)"
          end
        end

        private def create_files(context)
          app_files = Templates::App.app_files(context).map do |path, content|
            {"#{path_prefix(context)}#{path}", content}
          end

          create_app_files(Marten.apps.main, app_files)
        end

        private def generate_app(context)
          create_files(context)
          add_application_requirement(context)
          add_application_cli_requirement(context)
          add_application_to_installed_apps_setting(context)
          add_route_to_main_routes_map(context)
        end

        private def label_argument_description
          "Label of the application to generate"
        end

        private def located_in_apps_folder?
          Dir.exists?(Path.new(Marten.apps.main.class._marten_app_location).expand.join("apps"))
        end

        private def path_prefix(context)
          @path_prefix ||= located_in_apps_folder? ? "apps/#{context.label}/" : "#{context.label}/"
        end
      end
    end
  end
end
