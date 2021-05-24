require "./spec_helper"

describe Marten::Template::Context::BlockStack do
  describe "#add" do
    it "adds an array of block tags to the stack" do
      parser_1 = Marten::Template::Parser.new("content{% endblock %}")
      block_1 = Marten::Template::Tag::Block.new(parser_1, "block b1")

      parser_2 = Marten::Template::Parser.new("content{% endblock %}")
      block_2 = Marten::Template::Tag::Block.new(parser_2, "block b2")

      block_stack = Marten::Template::Context::BlockStack.new
      block_stack.add([block_1, block_2])

      block_stack.get("b1").should eq block_1
    end
  end

  describe "#get" do
    it "returns the last block for a given block name" do
      block_stack = Marten::Template::Context::BlockStack.new

      parser_1 = Marten::Template::Parser.new("content{% endblock %}")
      block_1 = Marten::Template::Tag::Block.new(parser_1, "block b1")

      parser_2 = Marten::Template::Parser.new("content{% endblock %}")
      block_2 = Marten::Template::Tag::Block.new(parser_2, "block b2")

      block_stack.add([block_1, block_2])

      parser_3 = Marten::Template::Parser.new("content{% endblock %}")
      block_3 = Marten::Template::Tag::Block.new(parser_3, "block b1")

      block_stack.add([block_3])

      block_stack.get("b1").should eq block_1
    end

    it "returns nil if the block is not in the stack" do
      block_stack = Marten::Template::Context::BlockStack.new
      block_stack.get("unknown").should be_nil
    end
  end

  describe "#pop" do
    it "removes the last block for a given block name from the stack" do
      block_stack = Marten::Template::Context::BlockStack.new

      parser_1 = Marten::Template::Parser.new("content{% endblock %}")
      block_1 = Marten::Template::Tag::Block.new(parser_1, "block b1")

      parser_2 = Marten::Template::Parser.new("content{% endblock %}")
      block_2 = Marten::Template::Tag::Block.new(parser_2, "block b2")

      block_stack.add([block_1, block_2])

      parser_3 = Marten::Template::Parser.new("content{% endblock %}")
      block_3 = Marten::Template::Tag::Block.new(parser_3, "block b1")

      block_stack.add([block_3])

      block_stack.pop("b1").should eq block_1
      block_stack.pop("b1").should eq block_3
    end

    it "returns nil if the block is not in the stack" do
      block_stack = Marten::Template::Context::BlockStack.new
      block_stack.pop("unknown").should be_nil
    end

    it "returns nil if blocks were in the stack but they are no longeer there" do
      block_stack = Marten::Template::Context::BlockStack.new

      parser = Marten::Template::Parser.new("content{% endblock %}")
      block = Marten::Template::Tag::Block.new(parser, "block b1")

      block_stack.push(block)
      block_stack.pop("b1")

      block_stack.pop("b1").should be_nil
    end
  end

  describe "#push" do
    it "allows to push a new block tag for a block name that is already in the stack" do
      block_stack = Marten::Template::Context::BlockStack.new

      parser_1 = Marten::Template::Parser.new("content{% endblock %}")
      block_1 = Marten::Template::Tag::Block.new(parser_1, "block b1")

      parser_2 = Marten::Template::Parser.new("content{% endblock %}")
      block_2 = Marten::Template::Tag::Block.new(parser_2, "block b2")

      block_stack.add([block_1, block_2])

      parser_3 = Marten::Template::Parser.new("content{% endblock %}")
      block_3 = Marten::Template::Tag::Block.new(parser_3, "block b1")

      block_stack.push(block_3)

      block_stack.pop("b1").should eq block_3
      block_stack.pop("b1").should eq block_1
    end

    it "allows to push a new block tag for a block name that is not already in the stack" do
      block_stack = Marten::Template::Context::BlockStack.new

      parser = Marten::Template::Parser.new("content{% endblock %}")
      block = Marten::Template::Tag::Block.new(parser, "block b1")

      block_stack.push(block)

      block_stack.pop("b1").should eq block
      block_stack.pop("b1").should be_nil
    end
  end
end
