module Marten
  module Views
    module Defaults
      module Debug
        class PageNotFound < View
          def dispatch
            if request.path == "/"
              render_welcome_page
            else
              HTTP::Response::NotFound.new("The requested resource was not found.", content_type: "text/html")
            end
          end

          private def render_welcome_page
            HTTP::Response.new(ECR.render("#{__DIR__}/templates/welcome.html.ecr"))
          end
        end
      end
    end
  end
end
