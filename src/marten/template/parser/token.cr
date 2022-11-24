module Marten
  module Template
    class Parser
      # Represents a token extracted during a lexical analysis.
      struct Token
        getter type
        getter content
        getter line_number

        def initialize(@type : TokenType, @content : String, @line_number : Int32)
        end
      end
    end
  end
end
