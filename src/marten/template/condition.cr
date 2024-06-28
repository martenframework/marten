module Marten
  module Template
    # A template condition.
    #
    # Condition expressions such as "var1 || var2" are parsed and evaluated using this abstraction.
    #
    # ```
    # context = Marten::Template::Context{"var1" => nil, "var2" => "42"}
    # Marten::Template::Condition.new(["var1", "||", "var2"]).parse.eval(context).truthy? # => true
    # ```
    class Condition
      @tokens : Array(Token::Base) = [] of Token::Base
      @current_token : Token::Base

      def initialize(parts : Array(String))
        # Convert each condition part string to corresponding condition tokens (operator and/or value).
        @tokens = parts.flat_map { |part| tokens_for(part) }
        @current_token = shift_token
      end

      # Consumes condition tokens until a token with a left binding power equal or lower than `rbp` is found.
      #
      # This method acts as the main entrypoint for the condition parser's top-down operator precedence parsing
      # algorithm (TDOP).
      def expression(rbp) : Token::Base
        # This method is called with a right binding power (rbp) as argument and the idea is to consume tokens until a
        # token with a lesser or equal binding power (lbp) is found. This involves processing all the intermediate
        # tokens that bind together and then returning the obtained token to the operator token that called the method.
        # Specific operator tokens will call this method too (by using their left binding power as argument) in order to
        # get the right token to consider in order to evaluate the corresponding conditions.
        token = @current_token
        @current_token = shift_token
        left = token.nud(self)

        while rbp < @current_token.lbp
          token = @current_token
          @current_token = shift_token
          left = token.led(self, left)
        end

        left
      end

      # Returns the condition token corresponding to the condition expression.
      #
      # The returned condition token can then be evaluated for a given template context.
      def parse : Token::Base
        # Triggers the start of the TDOP algorithm by starting with the first token and a right binding power of 0. The
        # obtained token will correspond to the full condition expression.
        result = expression(0)

        # If the last token is not the "end" token, it means that the initial condition expression is invalid because it
        # ends with unused operators or values.
        if @current_token.id != "end"
          raise Errors::InvalidSyntax.new("Condition expression ending with unused tokens: '#{@current_token}'")
        end

        result
      end

      private NEGATION_RE = /^!+/

      private def shift_token
        return Token::End.new if @tokens.empty?
        @tokens.shift
      end

      private def tokens_for(part)
        if !(operator_token_klass = Condition::Token::Operator.for(part)).nil?
          [operator_token_klass.new]
        else
          tokens_for_value(part)
        end
      end

      private def tokens_for_value(part)
        # Remove possible "not" sign (!) from the beginning of the part if present and infer if the value is negated.
        leading_exclamations_scan = part.scan(NEGATION_RE)
        sanitized_part = leading_exclamations_scan.empty? ? part : leading_exclamations_scan.first.post_match
        negated = (leading_exclamations_scan.first?.try(&.[0].size) || 0).odd?

        if negated
          [Condition::Token::Operator::Not.new, Condition::Token::Value.new(sanitized_part)] of Condition::Token::Base
        else
          [Condition::Token::Value.new(sanitized_part)] of Condition::Token::Base
        end
      end
    end
  end
end
