module Marten
  module CLI
    abstract class Generator
      class Schema < Generator
        module Templates
          def self.app_files(context : Context)
            [{"schemas/#{context.schema_filename}", ECR.render("#{__DIR__}/templates/schema.cr.ecr")}]
          end
        end
      end
    end
  end
end
