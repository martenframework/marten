module Marten
  module Template
    class Condition
      module Token
        # An end of expression token.
        class End < Base
          def eval(context : Context) : Marten::Template::Value
            raise NotImplementedError.new("End token should not be evaluated")
          end

          def id : String
            "end"
          end

          def lbp : UInt8
            0_u8
          end

          def nud(condition : Condition)
            raise Errors::InvalidSyntax.new("Unexpected end of expression")
          end
        end
      end
    end
  end
end
