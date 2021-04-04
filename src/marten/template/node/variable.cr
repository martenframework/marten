module Marten
  module Template
    module Node
      # Represents a variable node.
      #
      # A variable node will be resolved based on the current context in order to produce the final output.
      class Variable < Base
        def initialize(@expression : VariableExpression)
        end

        def render(context : Context) : String
          @expression.resolve(context).raw.to_s
        end
      end
    end
  end
end
