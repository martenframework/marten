module Marten
  module Views
    module Defaults
      module Debug
        # Handles page not found errors in debug mode.
        #
        # A "welcome" page is returned by this view if the requested path corresponds to the root of the application.
        # Otherwise, a standard "Page not found" response is returned.
        class PageNotFound < View
          @error : Exception? = nil

          getter error
          setter error

          def dispatch
            if request.path == "/"
              render_welcome_page
            else
              render_not_found_page
            end
          end

          private def render_not_found_page
            HTTP::Response.new(ECR.render("#{__DIR__}/templates/page_not_found.html.ecr"))
          end

          private def render_welcome_page
            HTTP::Response.new(ECR.render("#{__DIR__}/templates/welcome.html.ecr"))
          end
        end
      end
    end
  end
end
