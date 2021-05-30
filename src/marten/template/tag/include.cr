require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `include` template tag.
      class Include < Base
        include CanExtractAssignments
        include CanSplitSmartly

        @template_name_expression : FilterExpression
        @assignments : Hash(String, FilterExpression)

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          # Ensures that the include tag is not malformed and defines a template name at least.
          if parts.size < 2
            raise Errors::InvalidSyntax.new(
              "Malformed include tag: at least one argument must be provided (template name to include)"
            )
          end

          # Ensures that the third argument is 'with' when assignments are specified.
          if parts.size > 2 && parts[2] != "with"
            raise Errors::InvalidSyntax.new(
              "Malformed include tag: 'with' keyword expected to define variable assignments"
            )
          elsif parts.size == 3
            raise Errors::InvalidSyntax.new(
              "Malformed include tag: the 'with' keyword must be followed by variable assignments"
            )
          end

          @template_name_expression = FilterExpression.new(parts[1])

          @assignments = {} of String => FilterExpression
          extract_assignments(source).each do |name, value|
            if @assignments.has_key?(name)
              raise Errors::InvalidSyntax.new("Malformed include tag: '#{name}' variable defined more than once")
            end

            @assignments[name] = FilterExpression.new(value)
          end
        end

        def render(context : Context) : String
          if !(template_name = @template_name_expression.resolve(context).raw).is_a?(String)
            raise Errors::UnsupportedValue.new(
              "Template name name must resolve to a string, got a #{template_name.class} object"
            )
          end
          template = Marten.templates.get_template(template_name)

          rendered = ""

          context.stack do |include_context|
            @assignments.each do |name, expression|
              include_context[name] = expression.resolve(include_context)
            end

            rendered = template.render(include_context)
          end

          rendered
        end
      end
    end
  end
end
