module Marten
  module Template
    class Condition
      module Token
        module Operator
          # An infix operator token.
          class Infix < Base
            @first : Base? = nil
            @second : Base? = nil

            getter first
            getter second

            def eval(context : Context) : Marten::Template::Value
              raise NotImplementedError.new("Should be implemented by subclasses")
            end

            def id : String
              raise NotImplementedError.new("Should be implemented by subclasses")
            end

            def lbp : UInt8
              raise NotImplementedError.new("Should be implemented by subclasses")
            end

            def led(condition : Condition, left : Condition::Token::Base)
              @first = left
              @second = condition.expression(lbp)
              self
            end
          end
        end
      end
    end
  end
end
