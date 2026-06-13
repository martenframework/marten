module Marten
  module Template
    module Node
      # Represents a text node.
      #
      # A text will simply output its raw content at rendering time.
      class Text < Base
        def initialize(@source : String)
        end

        def render(context : Context) : String
          @source
        end

        # Returns a copy of the text node with trailing whitespace removed, or `nil` if the result is empty.
        def without_trailing_whitespace : Text?
          stripped = @source.rstrip
          return if stripped.empty?

          stripped == @source ? self : Text.new(stripped)
        end
      end
    end
  end
end
