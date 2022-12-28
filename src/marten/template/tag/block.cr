module Marten
  module Template
    module Tag
      # The `block` template tag.
      #
      # Blocks allow to define that some specific portions of a template can be overriden by child templates. This tag
      # is only useful when used in conjunction with the `extend` tag.
      class Block < Base
        @nodes : NodeSet
        @name : String

        getter name
        getter nodes

        def initialize(parser : Parser, source : String)
          parts = source.split

          # Ensures that the block tag is not malformed and defines a name.
          if parts.size != 2
            raise Errors::InvalidSyntax.new(
              "Malformed block tag:#{parts.size > 2 ? " only" : ""} one argument must be provided"
            )
          end

          @name = parts.last

          # Verifies that the considered block was not already encountered.
          if parser.encountered_block_names.includes?(parts.last)
            raise Errors::InvalidSyntax.new("Block with name '#{parts.last}' appears more than once")
          end
          parser.encountered_block_names << parts.last

          # Retrieves the inner nodes up to the endblock tag.
          @nodes = parser.parse(up_to: {"endblock"})
          parser.shift_token
        end

        def render(context : Context) : String
          String.build do |io|
            context.stack do |block_context|
              current_block = context.blocks.pop(name)
              block = current_block || self

              block_context[BLOCK_VARIABLE] = {name: block.name}

              io << block.nodes.render(block_context)

              context.blocks.push(current_block) if !current_block.nil?
            end
          end
        end

        private BLOCK_VARIABLE = "block"
      end
    end
  end
end
