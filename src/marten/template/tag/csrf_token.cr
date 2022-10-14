module Marten
  module Template
    module Tag
      # The `csrf_token` template tag.
      #
      # The `csrf_token` template tag allows to compute and insert the value of the CSRF token into a template. This
      # tag requires the presence of a handler object in the template context (under the `"handler"` key), otherwise an
      # empty token is returned.
      class CsrfToken < Base
        def initialize(_parser : Parser, _source : String)
        end

        def render(context : Context) : String
          handler = context["handler"]?.try(&.raw).as?(Handlers::Base)
          return "" if handler.nil?

          handler.get_csrf_token
        end
      end
    end
  end
end
