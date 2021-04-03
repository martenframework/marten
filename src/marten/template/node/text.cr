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
      end
    end
  end
end
