require "./spec_helper"

describe Marten::Template::Tag::Block do
  describe "::new" do
    it "can initialize a regular block tag as expected" do
      parser = Marten::Template::Parser.new("Example page{% endblock %}")
      tag = Marten::Template::Tag::Block.new(parser, "block page_title")
      tag.name.should eq "page_title"
    end

    it "properly marks the block as encountered at the parser level" do
      parser = Marten::Template::Parser.new("Example page{% endblock %}")
      Marten::Template::Tag::Block.new(parser, "block page_title")
      parser.encountered_block_names.includes?("page_title").should be_true
    end

    it "raises if the block tag does not define a name" do
      parser = Marten::Template::Parser.new("Example page{% endblock %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed block tag: one argument must be provided"
      ) do
        Marten::Template::Tag::Block.new(parser, "block")
      end
    end

    it "raises if the block tag contains more than the name argument" do
      parser = Marten::Template::Parser.new("Example page{% endblock %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed block tag: only one argument must be provided"
      ) do
        Marten::Template::Tag::Block.new(parser, "block page_title other")
      end
    end

    it "raises if the same block was already encountered by the parser" do
      parser = Marten::Template::Parser.new("Example page{% endblock %}")
      parser.encountered_block_names << "page_title"

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Block with name 'page_title' appears more than once"
      ) do
        Marten::Template::Tag::Block.new(parser, "block page_title")
      end
    end

    it "raises if the block is not closed as expected" do
      parser = Marten::Template::Parser.new("Example page")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unclosed tags, expected: endblock"
      ) do
        Marten::Template::Tag::Block.new(parser, "block page_title")
      end
    end
  end

  describe "#name" do
    it "returns the block name" do
      parser = Marten::Template::Parser.new("Example page{% endblock %}")
      tag = Marten::Template::Tag::Block.new(parser, "block page_title")
      tag.name.should eq "page_title"
    end
  end

  describe "#nodes" do
    it "returns the block nodes" do
      parser = Marten::Template::Parser.new("Example page{% endblock %}")
      tag = Marten::Template::Tag::Block.new(parser, "block page_title")
      tag.nodes.should be_a Marten::Template::NodeSet
    end
  end

  describe "#render" do
    it "renders a simple block in the context of a base template" do
      parser = Marten::Template::Parser.new("Hello from {{ page_name }} page{% endblock %}")
      tag = Marten::Template::Tag::Block.new(parser, "block page_title")

      tag.render(Marten::Template::Context{"page_name" => "test"}).should eq "Hello from test page"
    end

    it "renders the first block in the block stack for the considered block name when applicable" do
      other_parser = Marten::Template::Parser.new("{{ page_name }} PAGE{% endblock %}")
      other_tag = Marten::Template::Tag::Block.new(other_parser, "block page_title")

      parser = Marten::Template::Parser.new("Hello from {{ page_name }} page{% endblock %}")
      tag = Marten::Template::Tag::Block.new(parser, "block page_title")

      ctx = Marten::Template::Context{"page_name" => "TEST"}
      ctx.blocks.push(other_tag)

      tag.render(ctx).should eq "TEST PAGE"
    end

    it "exposes the block name as expected in the context" do
      parser = Marten::Template::Parser.new("Hello from {{ block.name }} block{% endblock %}")
      tag = Marten::Template::Tag::Block.new(parser, "block page_title")

      tag.render(Marten::Template::Context.new).should eq "Hello from page_title block"
    end
  end
end
