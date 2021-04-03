module Marten
  module Template
    class Parser
      # Holds all the types of tokens supported by the template language.
      enum TokenType
        COMMENT
        TAG
        TEXT
        VARIABLE
      end
    end
  end
end
