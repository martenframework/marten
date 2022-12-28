require "./concerns/*"
require "./for/*"

module Marten
  module Template
    module Tag
      # The `for` template tag.
      #
      # The `for` template tag allows to loop over the items of iterable objects. It supports unpacking multiple items
      # when applicable (eg. when iterating over hashes) and also handles fallbacks through the use of the `else` inner
      # block:
      #
      # ```
      # {% for item in items %}
      #   Display {{ item }}
      # {% else %}
      #   No items!
      # {% endfor %}
      # ```
      class For < Base
        include CanSplitSmartly

        @loop_vars : Array(String)
        @loop_nodes : NodeSet
        @else_nodes : NodeSet? = nil

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size < 4 || parts[-2] != "in"
            raise Errors::InvalidSyntax.new("For loops must have the following format: for x in y")
          end

          @loop_vars = parts[1...-2].join(' ').split(/ *, */)
          @loop_vars.each do |loop_var|
            next unless loop_var.empty? || loop_var.includes?(' ')
            raise Errors::InvalidSyntax.new("For loop has an invalid argument: #{source}")
          end

          @iterable_expression = FilterExpression.new(parts.last)

          @loop_nodes = parser.parse(up_to: {"else", "endfor"})
          token = parser.shift_token

          if token.content == "else"
            @else_nodes = parser.parse(up_to: {"endfor"})
            parser.shift_token
          end
        end

        def render(context : Context) : String
          parent_loop = context[LOOP_VARIABLE]?

          context.stack do |loop_context|
            items = @iterable_expression.resolve(loop_context)

            if items.empty?
              return @else_nodes.nil? ? "" : @else_nodes.not_nil!.render(loop_context)
            end

            loop = Loop.new(items_size: items.size, parent: parent_loop)
            loop_context[LOOP_VARIABLE] = loop

            String.build do |io|
              items.each_with_index do |item, index|
                # Prepare loop related attributes.
                loop.index = index

                if @loop_vars.size == 1
                  # No unpacking needed.
                  loop_context[@loop_vars.first] = item
                else
                  if item.raw.is_a?(Iterable)
                    item_arr = item.to_a
                    @loop_vars.each_with_index do |var, var_index|
                      if var_index + 1 > item_arr.size
                        raise Errors::UnsupportedType.new("Missing objects to unpack")
                      end

                      loop_context[var] = item_arr[var_index]
                    end
                  else
                    raise Errors::UnsupportedType.new(
                      "Unable to unpack #{item.raw.class} objects into multiple variables"
                    )
                  end
                end

                io << @loop_nodes.render(loop_context)
              end
            end
          end
        end

        private LOOP_VARIABLE = "loop"
      end
    end
  end
end
