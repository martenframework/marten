module Marten
  module Template
    class Condition
      module Token
        # The base condition token class.
        abstract class Base
          # Evaluates the token for a given context.
          abstract def eval(context : Context) : Marten::Template::Value

          # Returns the ID of the token.
          abstract def id : String

          # Returns the left binding power of the token.
          abstract def lbp : UInt8

          # Implements the infix handler and returns a resulting token.
          def led(condition : Condition, left : Condition::Token::Base) : Condition::Token::Base
            raise Errors::InvalidSyntax.new("Unexpected '#{id}' as infix operator")
          end

          # Implements the prefix handler and returns a resulting token.
          def nud(condition : Condition) : Condition::Token::Base
            raise Errors::InvalidSyntax.new("Unexpected '#{id}' as prefix operator")
          end

          def to_s(io)
            io << id
          end
        end
      end
    end
  end
end
