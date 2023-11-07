module Marten
  module CLI
    abstract class Generator
      class App < Generator
        module Templates
          def self.app_files(context : Context)
            path_prefix = path_prefix(context)

            [
              {"#{path_prefix}app.cr", ECR.render("#{__DIR__}/templates/app.cr.ecr")},
              {"#{path_prefix}cli.cr", ECR.render("#{__DIR__}/templates/cli.cr.ecr")},
              {"#{path_prefix}routes.cr", ECR.render("#{__DIR__}/templates/routes.cr.ecr")},
              {"#{path_prefix}emails/.gitkeep", gitkeep},
              {"#{path_prefix}handlers/.gitkeep", gitkeep},
              {"#{path_prefix}migrations/.gitkeep", gitkeep},
              {"#{path_prefix}models/.gitkeep", gitkeep},
              {"#{path_prefix}schemas/.gitkeep", gitkeep},
              {"#{path_prefix}templates/.gitkeep", gitkeep},
            ]
          end

          def self.path_prefix(context : Context)
            if context.located_in_apps_folder?
              "apps/#{context.label}/"
            else
              "#{context.label}/"
            end
          end

          private def self.gitkeep
            ECR.render("#{__DIR__}/templates/.gitkeep.ecr")
          end
        end
      end
    end
  end
end
