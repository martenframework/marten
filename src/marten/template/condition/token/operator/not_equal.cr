require "./infix"

module Marten
  module Template
    class Condition
      module Token
        module Operator
          # A not equal - `!=` - operator token.
          class NotEqual < Infix
            def eval(context : Context) : Marten::Template::Value
              Marten::Template::Value.from(@first.not_nil!.eval(context) != @second.not_nil!.eval(context))
            end

            def id : String
              "not_equal"
            end

            def lbp : UInt8
              10_u8
            end
          end
        end
      end
    end
  end
end
