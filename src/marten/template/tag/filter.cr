module Marten
  module Template
    module Tag
      # The `filter` template tag.
      #
      # The `filter` tag allows to apply one or more filters to the content of the tag. For example:
      #
      # ```html
      # {% filter upcase %}Hello {{ name }}!{% endfilter %}
      # {% filter upcase|truncate:8 %}Hello world, {{ name }}!{% endfilter %}
      # ```
      class Filter < Base
        @filter_expression : FilterExpression
        @filter_nodes : NodeSet

        def initialize(parser : Parser, source : String)
          parts = source.strip.split(/\s+/, limit: 2)

          if parts.size < 2
            raise Errors::InvalidSyntax.new("Malformed filter tag: at least one argument must be provided")
          end

          @filter_expression = FilterExpression.new("#{FILTER_VAR_NAME}|#{parts[1]}")

          @filter_expression.filter_names.each do |filter_name|
            if FORBIDDEN_FILTERS.includes?(filter_name)
              raise Errors::InvalidSyntax.new(
                %("filter #{filter_name}" is not permitted. Use the "escape" tag instead.)
              )
            end
          end

          @filter_nodes = parser.parse(up_to: {"endfilter"})
          parser.shift_token
        end

        def render(context : Context) : String
          rendered = @filter_nodes.render(context)
          context.stack do |inner_context|
            inner_context[FILTER_VAR_NAME] = rendered
            @filter_expression.resolve(inner_context).to_s
          end
        end

        private FILTER_VAR_NAME   = "v"
        private FORBIDDEN_FILTERS = {"escape", "safe"}
      end
    end
  end
end
