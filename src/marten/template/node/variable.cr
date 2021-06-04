module Marten
  module Template
    module Node
      # Represents a variable node.
      #
      # A variable node will be resolved based on the current context in order to produce the final output.
      class Variable < Base
        def initialize(source : String)
          @expression = FilterExpression.new(source)
        end

        def initialize(@expression : VariableExpression)
        end

        def render(context : Context) : String
          raw_value = @expression.resolve(context).try(&.raw)
          # Escapes the final value, except for safe strings.
          raw_value.is_a?(SafeString) ? raw_value.to_s : HTML.escape(raw_value.to_s)
        end
      end
    end
  end
end
