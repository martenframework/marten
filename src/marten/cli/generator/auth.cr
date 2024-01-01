require "./app"

module Marten
  module CLI
    abstract class Generator
      # Allows to generate the authentication application.
      class Auth < App
        help "Generate the authentication application."

        def run : Nil
          @app_label = "auth" if @app_label.empty?

          super
        end

        private def add_marten_auth_dependency(context)
          command.print("› Adding martenframework/marten-auth to shard.yml...", ending: "")
          shard_file = Path.new(Marten.apps.main.class._marten_app_location)
            .expand
            .join("../shard.yml")

          if File.exists?(shard_file)
            content = File.read(shard_file)

            dependencies_pattern = /dependencies:(.*?)(\Z|\n\s*\n)/m
            modified_content = if content.matches?(dependencies_pattern)
                                 content.gsub(dependencies_pattern) do |match|
                                   "#{match}\n  marten_auth:\n    github: martenframework/marten-auth\n"
                                 end
                               else
                                 content.sub(
                                   /(\Z|\n\s*\n)/,
                                   "dependencies:\n  marten_auth:\n    github: martenframework/marten-auth\n\\1"
                                 )
                               end

            File.open(shard_file, "w") do |f|
              f.rewind
              f.print(modified_content)
              f.truncate(f.pos)
            end

            command.print(command.style(" DONE", fore: :light_green, mode: :bold))
          else
            command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
            self.warnings << "Could not add marten-auth dependency (no shard.yml file)"
          end
        end

        private def add_marten_auth_requirement(context)
          command.print("› Adding marten-auth requirement...", ending: "")
          project_cr_file_path = Path.new(Marten.apps.main.class._marten_app_location).expand.join("project.cr")

          if File.exists?(project_cr_file_path)
            content = File.read(project_cr_file_path)

            marten_require_pattern = /require\s+"marten"(?:\s|$)/

            modified_content = if content.matches?(marten_require_pattern)
                                 content.gsub(marten_require_pattern) do |match|
                                   %{#{match}require "marten_auth"\n}
                                 end
                               else
                                 content.sub(/(\Z|\n)/, %{\nrequire "marten"\nrequire "marten_auth"\n\\1})
                               end

            File.open(project_cr_file_path, "w") do |f|
              f.rewind
              f.print(modified_content)
              f.truncate(f.pos)
            end

            command.print(command.style(" DONE", fore: :light_green, mode: :bold))
          else
            command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
            self.warnings << "Could not add marten-auth requirement to project.cr file (file not found)"
          end
        end

        private def add_marten_auth_middleware(context)
          command.print("› Adding auth middleware...", ending: "")
          base_settings_file = Path.new(Marten.apps.main.class._marten_app_location)
            .expand
            .join("../config/settings/base.cr")

          if File.exists?(base_settings_file)
            content = File.read(base_settings_file)

            # Find and modify the middleware array definition
            modified_content = content.gsub(/\h+(config\.middleware\s*=\s*\[[^\]]*\])/) do |match|
              middlewares = match
                .match(/\[([\s\S]*?)\]/)
                .not_nil![1]
                .split(",")
                .map(&.strip)
                .reject(&.empty?)

              middlewares << "MartenAuth::Middleware"

              [
                "  config.middleware = [",
                middlewares.map { |item| "    #{item}" }.join(",\n"),
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
              self.warnings << "Could not add auth middleware (setting not found)"
            end
          else
            command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
            self.warnings << "Could not add auth middleware (setting file not found)"
          end
        end

        private def add_marten_auth_user_model_setting(context)
          command.print("› Adding user model setting...", ending: "")
          base_settings_file = Path.new(Marten.apps.main.class._marten_app_location)
            .expand
            .join("../config/settings/base.cr")

          if File.exists?(base_settings_file)
            content = File.read(base_settings_file)

            unless content =~ /config\.auth\.user_model/
              modified_content = content.gsub(
                /Marten\.configure\s+do \|config\|\s*\n/,
                "Marten.configure do |config|" + "\n  config.auth.user_model = #{context.module_name}::User\n\n"
              )

              File.open(base_settings_file, "w") do |f|
                f.rewind
                f.print(modified_content)
                f.truncate(f.pos)
              end
            end

            command.print(command.style(" DONE", fore: :light_green, mode: :bold))
          else
            command.print(command.style(" SKIPPED", fore: :yellow, mode: :bold))
            self.warnings << "Could not add user model setting (setting file not found)"
          end
        end

        private def create_files(context)
          app_files = Templates::Auth.app_files(context).map do |path, content|
            {"#{path_prefix(context)}#{path}", content}
          end

          create_app_files(Marten.apps.main, app_files)
          create_spec_files(Templates::Auth.spec_files(context))
        end

        private def generate_app(context)
          super

          add_marten_auth_dependency(context)
          add_marten_auth_requirement(context)
          add_marten_auth_user_model_setting(context)
          add_marten_auth_middleware(context)
        end

        private def label_argument_description
          %{Label of the authentication application to generate (default to "auth")}
        end
      end
    end
  end
end
