module Marten
  module Template
    class Condition
      module Token
        # A condition value token.
        class Value < Base
          @filter_expression : FilterExpression?

          def initialize(source : String)
            @filter_expression = FilterExpression.new(source)
          end

          def initialize
          end

          def eval(context : Context) : Marten::Template::Value
            @filter_expression.not_nil!.resolve(context)
          end

          def id : String
            "value"
          end

          def lbp : UInt8
            0_u8
          end

          def nud(condition : Condition) : Condition::Token::Base
            self
          end
        end
      end
    end
  end
end
