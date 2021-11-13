module Marten
  module Template
    module Tag
      # The `csrf_token` template tag.
      #
      # The `csrf_token` template tag allows to compute and insert the value of the CSRF token into a template. This
      # tag requires the presence of a view object in the template context (under the `"view"` key), otherwise an empty
      # token is returned.
      class CsrfToken < Base
        def initialize(_parser : Parser, _source : String)
        end

        def render(context : Context) : String
          view = context["view"]?.try(&.raw).as?(Views::Base)
          return "" if view.nil?

          view.get_csrf_token
        end
      end
    end
  end
end
