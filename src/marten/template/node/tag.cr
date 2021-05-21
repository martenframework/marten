module Marten
  module Template
    module Node
      # Represents a tag node.
      #
      # A tag node will be resolved based on the current context in order to produce the final output. Tag nodes are
      # initialized from a `source` string that corresponds to the tag usage and from the `parser`
      # (`Marten::Template::Parser` object) that initiated their initializations. This is because tag nodes can trigger
      # the parsing of possible inner nodes, up to the a closing tag (for example `{% if ... %}` up to `{% endif %}`).
      class Tag < Base
        @tag : Marten::Template::Tag::Base

        # Returns the tag instance initialized for the current node.
        getter tag

        def initialize(parser : Parser, source : String)
          @tag = Marten::Template::Tag.get(source.split.first).new(parser, source)
        end

        # Returns the string representation of the tag node for a given context.
        def render(context : Context) : String
          @tag.render(context)
        end
      end
    end
  end
end
