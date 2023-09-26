module Marten
  module CLI
    abstract class Generator
      class Model < Generator
        module Templates
          def self.app_files(context : Context)
            [{"models/#{context.model_filename}", ECR.render("#{__DIR__}/templates/model.cr.ecr")}]
          end
        end
      end
    end
  end
end
