require "./infix"

module Marten
  module Template
    class Condition
      module Token
        module Operator
          # A greater than - `>` - operator token.
          class GreaterThan < Infix
            def eval(context : Context) : Marten::Template::Value
              Marten::Template::Value.from(@first.not_nil!.eval(context) > @second.not_nil!.eval(context))
            end

            def id : String
              "greater_than"
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
