module Marten
  module CLI
    abstract class Generator
      class Email < Generator
        module Templates
          def self.app_files(context : Context)
            files = Array(Tuple(String, String)).new

            files << {"emails/#{context.email_filename}", ECR.render("#{__DIR__}/templates/email.cr.ecr")}
            files << {
              "templates/#{context.html_template_filepath}",
              ECR.render("#{__DIR__}/templates/template.html.ecr"),
            }
            files << {
              "templates/#{context.text_template_filepath}",
              ECR.render("#{__DIR__}/templates/template.txt.ecr"),
            }

            files
          end
        end
      end
    end
  end
end
