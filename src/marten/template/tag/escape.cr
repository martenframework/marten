module Marten
  module Template
    module Tag
      # The `escape` template tag.
      #
      # The `escape` tag is used to enable or disable auto-escaping for a block of code. It takes one argument, either
      # `on` or `off`, to enable or disable auto-escaping, respectively.
      #
      # For example:
      #
      # ```
      # {% escape off %}
      #  <div>{{ article.html_body }}</div>
      # {% endescape %}
      # ```
      class Escape < Base
        @nodes : NodeSet
        @enabled : Bool

        def initialize(parser : Parser, source : String)
          parts = source.split

          # Ensures that the autoescape tag is not malformed and defines the expected boolean.
          if parts.size != 2
            raise Errors::InvalidSyntax.new(
              "Malformed escape tag:#{parts.size > 2 ? " only" : ""} one argument must be provided"
            )
          end

          if parts.last != ESCAPE_ON && parts.last != ESCAPE_OFF
            raise Errors::InvalidSyntax.new(
              "Malformed escape tag: the argument must be either #{ESCAPE_ON} or #{ESCAPE_OFF}"
            )
          end

          @enabled = parts.last == ESCAPE_ON

          # Retrieves the inner nodes up to the endblock tag.
          @nodes = parser.parse(up_to: {"endescape"})
          parser.shift_token
        end

        def render(context : Context) : String
          context.with_escape(enabled?) do
            @nodes.render(context)
          end
        end

        private ESCAPE_ON  = "on"
        private ESCAPE_OFF = "off"

        private getter nodes

        private getter? enabled
      end
    end
  end
end
