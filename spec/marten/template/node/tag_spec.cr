require "./spec_helper"

describe Marten::Template::Node::Tag do
  describe "::new" do
    it "raises if the tag is not found" do
      parser = Marten::Template::Parser.new("")
      expect_raises(Marten::Template::Errors::InvalidSyntax, "Unknown tag with name 'unknown'") do
        Marten::Template::Node::Tag.new(parser, "unknown")
      end
    end
  end

  describe "#render" do
    it "returns the string representation of the tag for a given context" do
      parser = Marten::Template::Parser.new(
        "<strong>Hello {{ user }}</strong>      <span>Test</span>{% endspaceless %}"
      )
      node = Marten::Template::Node::Tag.new(parser, "spaceless")
      node.render(Marten::Template::Context{"user" => "John Doe"}).should eq(
        "<strong>Hello John Doe</strong><span>Test</span>"
      )
    end
  end

  describe "#tag" do
    it "returns the tag instance associated with the current node" do
      parser = Marten::Template::Parser.new(
        "<strong>Hello {{ user }}</strong>      <span>Test</span>{% endspaceless %}"
      )
      node = Marten::Template::Node::Tag.new(parser, "spaceless")
      node.tag.should be_a Marten::Template::Tag::Spaceless
    end
  end
end
