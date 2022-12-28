module Marten
  module Template
    module Tag
      # The `verbatim` template tag.
      #
      # The `{% verbatim %}...{% endverbatim %}` template tag prevents the content of the tag to be processed by the
      # template engine. For example:
      #
      # ```
      # {% verbatim %}
      #   This should not be {{ processed }}.
      # {% endverbaim %}
      # ```
      class Verbatim < Base
        @inner_nodes : NodeSet

        def initialize(parser : Parser, source : String)
          @inner_nodes = parser.parse(up_to: {"endverbatim"})
          parser.shift_token
        end

        def render(context : Context) : String
          @inner_nodes.render(context)
        end
      end
    end
  end
end
