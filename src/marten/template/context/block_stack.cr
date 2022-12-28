module Marten
  module Template
    class Context
      # Represents a stack of blocks used for a given context.
      class BlockStack
        def initialize
          @blocks = {} of String => Deque(Tag::Block)
        end

        # Adds an array of block tags to the stack.
        def add(blocks : Array(Tag::Block)) : Nil
          blocks.each do |block|
            @blocks[block.name] ||= Deque(Tag::Block).new
            @blocks[block.name].unshift(block)
          end
        end

        # Returns the latest block tag for a given name.
        def get(name : String)
          @blocks[name]?.try(&.last)
        end

        # Removes the latest block tag associated with the passed name from the stack.
        def pop(name : String)
          @blocks[name]?.try(&.pop)
        rescue IndexError
          nil
        end

        # Pushes a block tag to the stack.
        def push(block : Tag::Block) : Nil
          @blocks[block.name] ||= Deque(Tag::Block).new
          @blocks[block.name].push(block)
        end
      end
    end
  end
end
