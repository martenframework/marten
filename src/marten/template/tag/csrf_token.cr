require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `csrf_token` template tag.
      #
      # The `csrf_token` template tag allows to compute and insert the value of the CSRF token into a template. This
      # tag requires the presence of a handler object in the template context (under the `"handler"` key), otherwise an
      # empty token is returned.
      #
      # Optionally, the output of this tag can be assigned to a specific variable using the `as` keyword:
      #
      # ```
      # {% csrf_token as my_var %}
      # ```
      class CsrfToken < Base
        include CanSplitSmartly

        @assigned_to : String? = nil

        def initialize(_parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size == 2 || parts.size > 3
            raise Errors::InvalidSyntax.new("Malformed csrf_token tag: either no arguments or two arguments expected")
          end

          if parts.size == 3 && parts[1] == "as"
            @assigned_to = parts[2]
          elsif parts.size == 3
            raise Errors::InvalidSyntax.new("Malformed csrf_token tag: 'as' keyword expected")
          end
        end

        def render(context : Context) : String
          handler = context["handler"]?.try(&.raw).as?(Handlers::Base)
          return "" if handler.nil?

          if @assigned_to.nil?
            handler.get_csrf_token
          else
            context[@assigned_to.not_nil!] = handler.get_csrf_token
            ""
          end
        end
      end
    end
  end
end
