require "./prefix"

module Marten
  module Template
    class Condition
      module Token
        module Operator
          # A not operator token.
          class Not < Prefix
            def eval(context : Context) : Marten::Template::Value
              Marten::Template::Value.from(!@first.not_nil!.eval(context).raw)
            end

            def id : String
              "not"
            end

            def lbp : UInt8
              8_u8
            end
          end
        end
      end
    end
  end
end
