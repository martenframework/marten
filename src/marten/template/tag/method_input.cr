require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `method_input` template tag.
      #
      # The `method_input` template tag generates a hidden HTML input field for simulating HTTP methods in forms.
      # This tag takes a single argument specifying the desired HTTP method (e.g., "DELETE", "PUT").
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
