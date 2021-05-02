require "./infix"

module Marten
  module Template
    class Condition
      module Token
        module Operator
          # An and - `&&` - operator token.
          class And < Infix
            def eval(context : Context) : Marten::Template::Value
              Marten::Template::Value.from(
                @first.not_nil!.eval(context).raw &&
                @second.not_nil!.eval(context).raw
              )
            end

            def id : String
              "and"
            end

            def lbp : UInt8
              7_u8
            end
          end
        end
      end
    end
  end
end
