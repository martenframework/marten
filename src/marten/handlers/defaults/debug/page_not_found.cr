module Marten
  module Handlers
    module Defaults
      module Debug
        # Handles page not found errors in debug mode.
        #
        # A "welcome" page is returned by this Handler if the requested path corresponds to the root of the application.
        # Otherwise, a standard "Page not found" response is returned.
        class PageNotFound < Handler
          @auth_available = false
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

          private getter? auth_available

          private def render_not_found_page
            HTTP::Response::NotFound.new(ECR.render("#{__DIR__}/templates/page_not_found.html.ecr"))
          end

          private def render_welcome_page
            begin
              Marten.routes.reverse("auth:sign_up")
              @auth_available = true
            rescue Routing::Errors::NoReverseMatch
            end

            HTTP::Response.new(ECR.render("#{__DIR__}/templates/welcome.html.ecr"))
          end
        end
      end
    end
  end
end
