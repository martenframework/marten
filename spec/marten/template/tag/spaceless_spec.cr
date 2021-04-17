require "./spec_helper"

describe Marten::Template::Tag::Spaceless do
  describe "::new" do
    it "raises if the block is not closed as expected" do
      parser = Marten::Template::Parser.new(
        "<strong>Hello {{ user }}</strong>      <span>Test</span>"
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unclosed tags, expected: endspaceless"
      ) do
        Marten::Template::Tag::Spaceless.new(parser, "spaceless")
      end
    end
  end

  describe "#render" do
    it "removes whitespaces between tags" do
      parser = Marten::Template::Parser.new(
        "<strong>Hello {{ user }}</strong>      <span>Test</span>{% endspaceless %}"
      )
      tag = Marten::Template::Tag::Spaceless.new(parser, "spaceless")
      tag.render(Marten::Template::Context{"user" => "John Doe"}).should eq(
        "<strong>Hello John Doe</strong><span>Test</span>"
      )
    end

    it "removes newlines between tags" do
      parser = Marten::Template::Parser.new(
        "<strong>Hello {{ user }}</strong>  \n  <span>Test</span>{% endspaceless %}"
      )
      tag = Marten::Template::Tag::Spaceless.new(parser, "spaceless")
      tag.render(Marten::Template::Context{"user" => "John Doe"}).should eq(
        "<strong>Hello John Doe</strong><span>Test</span>"
      )
    end

    it "removes tabs between tags" do
      parser = Marten::Template::Parser.new(
        "<strong>Hello {{ user }}</strong>    \t\t  <span>Test</span>{% endspaceless %}"
      )
      tag = Marten::Template::Tag::Spaceless.new(parser, "spaceless")
      tag.render(Marten::Template::Context{"user" => "John Doe"}).should eq(
        "<strong>Hello John Doe</strong><span>Test</span>"
      )
    end

    it "does not remove whitespaces inside tags" do
      parser = Marten::Template::Parser.new(
        "<strong>   Hello {{ user }}</strong>      <span>Test   </span>{% endspaceless %}"
      )
      tag = Marten::Template::Tag::Spaceless.new(parser, "spaceless")
      tag.render(Marten::Template::Context{"user" => "John Doe"}).should eq(
        "<strong>   Hello John Doe</strong><span>Test   </span>"
      )
    end
  end
end
