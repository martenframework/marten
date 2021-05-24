require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `extend` template tag.
      #
      # The `extend` template tag allows to define that a template inherits from a specific base template. This tag
      # must be used with one mandatory argument, which can be either a string literal or a variable that will be
      # resolved at runtime. This mechanism is useful only if the base template defines blocks that are overriden or
      # extended by the child template.
      class Extend < Base
        include CanSplitSmartly

        @nodes : NodeSet
        @block_tags : Array(Tag::Block)

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          # Ensures that the extend tag is not malformed and defines a template name.
          if parts.size != 2
            raise Errors::InvalidSyntax.new(
              "Malformed extend tag:#{parts.size > 2 ? " only" : ""} one argument must be provided"
            )
          end

          # Processes the parent template name as a regular filter expression and retrieves the remining nodes.
          @parent_name_expression = FilterExpression.new(parts[1])
          @nodes = parser.parse
          @block_tags = @nodes.compact_map do |n|
            next if !(tag_node = n).is_a?(Node::Tag)
            next if !tag_node.tag.is_a?(Tag::Block)
            tag_node.tag.as(Tag::Block)
          end

          # Ensures that no other extend tag is in the present template.
          if @nodes.any? { |n| (tag_node = n).is_a?(Node::Tag) && tag_node.tag.is_a?(Tag::Extend) }
            raise Errors::InvalidSyntax.new("Only one extend tag is allowed per template")
          end
        end

        def render(context : Context) : String
          # First tries to get the compiled parent template.
          if !(parent_name = @parent_name_expression.resolve(context).raw).is_a?(String)
            raise Errors::UnsupportedValue.new(
              "Template parent name must resolve to a string, got a #{parent_name.class} object"
            )
          end
          compiled_parent = Marten.templates.get_template(parent_name)

          # Adds the blocks of the current template to the block stack.
          context.blocks.add(@block_tags)

          # Tries to identify whether the parent template is the root template (which means that it does not extend
          # another template). If this is the case, its block tags must be added to block stack as well because they
          # might be rendered.
          compiled_parent_is_root = false
          compiled_parent.nodes.each do |node|
            next if node.is_a?(Node::Text)
            compiled_parent_is_root = (tag_node = node).is_a?(Node::Tag) && !tag_node.tag.is_a?(Tag::Extend)
            break
          end

          if compiled_parent_is_root
            block_tags = compiled_parent.nodes.compact_map do |n|
              next if !(tag_node = n).is_a?(Node::Tag)
              next if !tag_node.tag.is_a?(Tag::Block)
              tag_node.tag.as(Tag::Block)
            end

            context.blocks.add(block_tags)
          end

          # Finally renders the parent template.
          compiled_parent.render(context)
        end
      end
    end
  end
end
