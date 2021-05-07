require "./infix"

module Marten
  module Template
    class Condition
      module Token
        module Operator
          # An in operator token.
          class In < Infix
            def eval(context : Context) : Marten::Template::Value
              Marten::Template::Value.from(@second.not_nil!.eval(context).includes?(@first.not_nil!.eval(context)))
            end

            def id : String
              "in"
            end

            def lbp : UInt8
              9_u8
            end
          end
        end
      end
    end
  end
end
