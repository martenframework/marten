require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `csrf_token` template tag.
      #
      # The `csrf_token` template tag allows to compute and insert the value of the CSRF token into a template. This
      # tag requires the presence of a handler object in the template context (under the `"handler"` key), otherwise an
      # empty token is returned.
      class MethodInput < Base
        include CanSplitSmartly

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size != 2
            raise Errors::InvalidSyntax.new("Malformed method_input tag: exactly one argument must be provided")
          end

          @method_type_expression = FilterExpression.new(parts[1])
        end

        def render(context : Context) : String
          method_type = @method_type_expression.resolve(context).to_s

          %(<input type="hidden" name="_method" value="#{method_type}">)
        end
      end
    end
  end
end
