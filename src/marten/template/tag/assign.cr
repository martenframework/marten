require "./base"
require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `assign` template tag.
      #
      # The `assign` template tag allows to define new variables that will be stored in the template's context:
      #
      # ```
      # {% assign my_var = "Hello World!" %}
      # ```
      class Assign < Base
        include CanExtractAssignments

        @assigned_to : String
        @value_expression : FilterExpression

        def initialize(parser : Parser, source : String)
          assignments = extract_assignments(source)
          if assignments.size != 1
            raise Errors::InvalidSyntax.new(
              "Malformed assign tag:#{assignments.size > 1 ? " only" : ""} one assignment must be specified"
            )
          end

          @assigned_to = assignments.first[0]
          @value_expression = FilterExpression.new(assignments.first[1])
        end

        def render(context : Context) : String
          context[@assigned_to] = @value_expression.resolve(context)

          ""
        end
      end
    end
  end
end
