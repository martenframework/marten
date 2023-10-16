module Marten
  module CLI
    abstract class Generator
      class Handler < Generator
        module Templates
          def self.app_files(context : Context)
            [{"handlers/#{context.handler_filename}", ECR.render("#{__DIR__}/templates/handler.cr.ecr")}]
          end
        end
      end
    end
  end
end
