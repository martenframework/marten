require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `csrf_input` template tag.
      #
      # The `csrf_input` tag generates a hidden html input tag with `csrftoken` as name and
      # the output of `csrf_token` tag as value.
      #
      # ```html
      # <input type="hidden" name="csrftoken" value="randomStrinGgenEratedbyCSRFtoken" />
      # ```
      class CsrfInput < Base
        include CanSplitSmartly

        @assigned_to : String? = nil

        def initialize(_parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size != 1
            raise Errors::InvalidSyntax.new("Malformed csrf_input tag: takes no argument")
          end
        end

        def render(context : Context) : String
          return "" if (handler = context.handler).nil?

          %(<input type="hidden" name="csrftoken" value="#{handler.get_csrf_token}" />)
        end
      end
    end
  end
end
