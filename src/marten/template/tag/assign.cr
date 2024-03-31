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
      #
      # It is also possible to use the `unless defined` modifier to only assign the variable if it is not already
      # defined in the template context. For example:
      #
      # ```
      # {% assign my_var = "Hello World!" unless defined %}
      # ```
      class Assign < Base
        include CanExtractAssignments
        include CanSplitSmartly

        @assigned_to : String
        @unless_defined : Bool = false
        @value_expression : FilterExpression

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)
          if parts[-2..]? == UNLESS_DEFINED_PARTS
            @unless_defined = true
            source = parts[0..-3].join(" ")
          end

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
          if !unless_defined? || !context.has_key?(@assigned_to)
            context[@assigned_to] = @value_expression.resolve(context)
          end

          ""
        end

        private UNLESS_DEFINED_PARTS = ["unless", "defined"]

        private getter? unless_defined
      end
    end
  end
end
