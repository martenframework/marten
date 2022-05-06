require "./spec_helper"

describe Marten::Template::Tag::Verbatim do
  describe "::new" do
    it "raises if the block is not closed as expected" do
      parser = Marten::Template::Parser.new(
        "<strong>Hello {{ user }}</strong>      <span>Test</span>"
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unclosed tags, expected: endverbatim"
      ) do
        Marten::Template::Tag::Verbatim.new(parser, "verbatim")
      end
    end
  end

  describe "#render" do
    it "renders the inner content as is" do
      parser = Marten::Template::Parser.new(
        "{% verbatim %}<strong>Hello {{ user }}</strong>      <span>Test</span>{% endverbatim %}"
      )
      parser.shift_token

      tag = Marten::Template::Tag::Verbatim.new(parser, "verbatim")
      tag.render(Marten::Template::Context.new).should eq(
        "<strong>Hello {{ user }}</strong>      <span>Test</span>"
      )
    end
  end
end
