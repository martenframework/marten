require "./infix"

module Marten
  module Template
    class Condition
      module Token
        module Operator
          # An or - `||` - operator token.
          class Or < Infix
            def eval(context : Context) : Marten::Template::Value
              Marten::Template::Value.from(
                @first.not_nil!.eval(context).raw ||
                @second.not_nil!.eval(context).raw
              )
            end

            def id : String
              "or"
            end

            def lbp : UInt8
              6_u8
            end
          end
        end
      end
    end
  end
end
