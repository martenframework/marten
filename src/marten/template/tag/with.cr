require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `with` template tag.
      #
      # The `with` template tag allows to assign local variables inside a block.
      # After the block is done the assigned variables are no longer available.
      # block:
      #
      # ```
      # {% with var1=2(, var2="Hello World") %}
      #   {{ var1 }} {{ var2 }}
      # {% endwith %}
      # ```
      class With < Base
        include CanExtractAssignments

        @assignments : Array(Tuple(String, FilterExpression))
        @with_nodes : NodeSet

        def initialize(parser : Parser, source : String)
          assignments = extract_assignments(source)
          @with_nodes = parser.parse(up_to: {"endwith"})
          parser.shift_token

          if assignments.size == 0
            raise Errors::InvalidSyntax.new(
              "Malformed with tag:at least one assignment must be present"
            )
          end

          @assignments = assignments.map do |variable_name, raw_filter_expression|
            {variable_name, FilterExpression.new(raw_filter_expression)}
          end
        end

        def render(context : Context) : String
          context.stack do |with_context|
            String.build do |io|
              @assignments.each do |assignment|
                context[assignment[0]] = assignment[1].resolve(context)
              end

              io << @with_nodes.render(with_context)
            end
          end
        end
      end
    end
  end
end
