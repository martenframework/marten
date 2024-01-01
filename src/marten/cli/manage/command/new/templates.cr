module Marten
  module CLI
    class Manage
      module Command
        class New < Base
          module Templates
            def self.app_files(context : Context)
              files = Array(Tuple(String, String)).new

              src_path = "src/#{context.name}/"

              files << {"#{src_path}app.cr", ECR.render("#{__DIR__}/templates/app/src/app/app.cr.ecr")}
              files << {"#{src_path}cli.cr", ECR.render("#{__DIR__}/templates/app/src/app/cli.cr.ecr")}
              files << {"#{src_path}routes.cr", ECR.render("#{__DIR__}/templates/app/src/app/routes.cr.ecr")}
              files << {"#{src_path}emails/.gitkeep", GITKEEP}
              files << {"#{src_path}handlers/.gitkeep", GITKEEP}
              files << {"#{src_path}migrations/.gitkeep", GITKEEP}
              files << {"#{src_path}models/.gitkeep", GITKEEP}
              files << {"#{src_path}schemas/.gitkeep", GITKEEP}
              files << {"#{src_path}templates/.gitkeep", GITKEEP}
              files << {"src/#{context.name}.cr", ECR.render("#{__DIR__}/templates/app/src/app.cr.ecr")}
              files << {".editorconfig", editorconfig}
              files << {".gitignore", gitignore}
              files << {"shard.yml", ECR.render("#{__DIR__}/templates/app/shard.yml.ecr")}

              files << {"spec/spec_helper.cr", ECR.render("#{__DIR__}/templates/app/spec/spec_helper.cr.ecr")}

              files
            end

            def self.project_files(context : Context)
              files = Array(Tuple(String, String)).new

              # Config files
              files << {"config/initializers/.gitkeep", GITKEEP}
              files << {
                "config/settings/base.cr",
                ECR.render("#{__DIR__}/templates/project/config/settings/base.cr.ecr"),
              }
              files << {
                "config/settings/development.cr",
                ECR.render("#{__DIR__}/templates/project/config/settings/development.cr.ecr"),
              }
              files << {
                "config/settings/production.cr",
                ECR.render("#{__DIR__}/templates/project/config/settings/production.cr.ecr"),
              }
              files << {
                "config/settings/test.cr",
                ECR.render("#{__DIR__}/templates/project/config/settings/test.cr.ecr"),
              }
              files << {"config/routes.cr", ECR.render("#{__DIR__}/templates/project/config/routes.cr.ecr")}

              # Spec files
              files << {"spec/spec_helper.cr", ECR.render("#{__DIR__}/templates/project/spec/spec_helper.cr.ecr")}

              # Source files
              files << {"src/assets/css/app.css", ECR.render("#{__DIR__}/templates/project/src/assets/css/app.css.ecr")}
              files << {"src/cli.cr", ECR.render("#{__DIR__}/templates/project/src/cli.cr.ecr")}
              files << {"src/project.cr", ECR.render("#{__DIR__}/templates/project/src/project.cr.ecr")}
              files << {"src/server.cr", ECR.render("#{__DIR__}/templates/project/src/server.cr.ecr")}
              files << {"src/emails/.gitkeep", GITKEEP}
              files << {"src/handlers/.gitkeep", GITKEEP}
              files << {"src/migrations/.gitkeep", GITKEEP}
              files << {"src/models/.gitkeep", GITKEEP}
              files << {"src/schemas/.gitkeep", GITKEEP}
              files << {
                "src/templates/base.html",
                ECR.render("#{__DIR__}/templates/project/src/templates/base.html.ecr"),
              }

              # Other files
              files << {".editorconfig", editorconfig}
              files << {".gitignore", gitignore}
              files << {"manage.cr", ECR.render("#{__DIR__}/templates/project/manage.cr.ecr")}
              files << {"shard.yml", ECR.render("#{__DIR__}/templates/project/shard.yml.ecr")}

              # Add authentification files if needed.
              if context.targets_auth?
                auth_context = CLI::Templates::App::Context.new("auth")
                auth_app_files = CLI::Templates::Auth.app_files(auth_context).map do |path, content|
                  {"src/apps/auth/#{path}", content}
                end
                spec_app_files = CLI::Templates::Auth.spec_files(auth_context).map do |path, content|
                  {"spec/#{path}", content}
                end

                files += auth_app_files
                files += spec_app_files
              end

              files
            end

            private GITKEEP = ""

            private def self.editorconfig
              ECR.render("#{__DIR__}/templates/shared/.editorconfig.ecr")
            end

            private def self.gitignore
              ECR.render("#{__DIR__}/templates/shared/.gitignore.ecr")
            end
          end
        end
      end
    end
  end
end
