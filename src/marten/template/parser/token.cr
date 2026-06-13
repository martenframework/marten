module Marten
  module Template
    class Parser
      # Represents a token extracted during a lexical analysis.
      struct Token
        getter type
        getter content
        getter line_number

        getter? trim_left
        getter? trim_right

        def initialize(
          @type : TokenType,
          @content : String,
          @line_number : Int32,
          @trim_left = false,
          @trim_right = false,
        )
        end
      end
    end
  end
end
