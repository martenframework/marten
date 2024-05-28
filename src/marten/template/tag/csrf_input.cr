require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `csrf_input` template tag.
      #
      # The `csrf_input` template tag allows generating a hidden HTML input tag containing the CSRF token.
      #
      # For example, using `{% csrf_input %}` in a template will generate the following HTML:
      #
      # ```html
      # <input type="hidden" name="csrftoken" value="<csrfToken>" />
      # ```
      #
      # Where `<csrfToken>` is the actual CSRF token.
      #
      # Optionally, the output of this tag can be assigned to a specific variable using the `as` keyword:
      #
      # ```
      # {% csrf_input as my_csrf_input %}
      # ```
      class CsrfInput < Base
        include CanSplitSmartly

        @assigned_to : String? = nil

        def initialize(_parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size == 2 || parts.size > 3
            raise Errors::InvalidSyntax.new("Malformed csrf_input tag: either no arguments or two arguments expected")
          end

          if parts.size == 3 && parts[1] == "as"
            @assigned_to = parts[2]
          elsif parts.size == 3
            raise Errors::InvalidSyntax.new("Malformed csrf_input tag: 'as' keyword expected")
          end
        end

        def render(context : Context) : String
          return "" if (handler = context.handler).nil?

          input = %(<input type="hidden" name="csrftoken" value="#{handler.get_csrf_token}" />)

          if @assigned_to.nil?
            input
          else
            context[@assigned_to.not_nil!] = SafeString.new(input)
            ""
          end
        end
      end
    end
  end
end
