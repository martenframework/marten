module Marten
  module Template
    class Condition
      module Token
        module Operator
          # A prefix operator token.
          class Prefix < Base
            @first : Base? = nil

            getter first

            def eval(context : Context) : Marten::Template::Value
              raise NotImplementedError.new("Should be implemented by subclasses")
            end

            def id : String
              raise NotImplementedError.new("Should be implemented by subclasses")
            end

            def lbp : UInt8
              raise NotImplementedError.new("Should be implemented by subclasses")
            end

            def nud(condition : Condition) : Condition::Token::Base
              @first = condition.expression(lbp)
              self
            end
          end
        end
      end
    end
  end
end
