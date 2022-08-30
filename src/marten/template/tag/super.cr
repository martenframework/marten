module Marten
  module Template
    module Tag
      # The `super` template tag.
      #
      # The `super` template tag allows to render the content of a block from a parent template (in a situation where
      # both the `extend` and `block` tags are used). This can be useful in situations where blocks in a child template
      # need to extend (add content) to a parent's block content instead of overwriting it.
      class Super < Base
        def initialize(parser : Parser, source : String)
        end

        def render(context : Context) : String
          block_data = context["block"]?
          raise Errors::InvalidSyntax.new("super must be called from whithin a block tag") if block_data.nil?

          parent_block = context.blocks.get(block_data.not_nil!["name"].raw.as(String))
          parent_block.nil? ? "" : parent_block.not_nil!.render(context)
        end
      end
    end
  end
end
