require "./app/**"

module Marten
  module CLI
    module Templates
      module App
        def self.app_files(context : Context)
          [
            {"app.cr", ECR.render("#{__DIR__}/app/templates/app.cr.ecr")},
            {"cli.cr", ECR.render("#{__DIR__}/app/templates/cli.cr.ecr")},
            {"routes.cr", ECR.render("#{__DIR__}/app/templates/routes.cr.ecr")},
            {"emails/.gitkeep", GITKEEP},
            {"handlers/.gitkeep", GITKEEP},
            {"migrations/.gitkeep", GITKEEP},
            {"models/.gitkeep", GITKEEP},
            {"schemas/.gitkeep", GITKEEP},
            {"templates/.gitkeep", GITKEEP},
          ]
        end

        private GITKEEP = ""
      end
    end
  end
end
