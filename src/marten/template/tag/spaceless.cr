module Marten
  module Template
    module Tag
      # The `spaceless` template tag.
      #
      # The `{% spaceless %}...{% endspaceless %}` template tag allows remove whitespaces, tabs and new lines between
      # HTML tags. Whitespaces inside tags are left untouched.
      class Spaceless < Base
        @inner_nodes : NodeSet

        def initialize(parser : Parser, source : String)
          @inner_nodes = parser.parse(up_to: {"endspaceless"})
          parser.shift_token
        end

        def render(context : Context) : String
          @inner_nodes.render(context).strip.gsub(/>\s+</, "><")
        end
      end
    end
  end
end
