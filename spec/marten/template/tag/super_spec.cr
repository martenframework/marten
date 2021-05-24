require "./spec_helper"

describe Marten::Template::Tag::Super do
  describe "#render" do
    it "renders the parent block's content as expected" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {% extend "base.html" %}
        {% block title %}{% super %} - Local title{% endblock %}
        TEMPLATE
      )
      nodes = parser.parse
      nodes.render(Marten::Template::Context.new).includes?("<title>Test project - Local title</title>").should be_true
    end

    it "raises if the super block is not used from within a block tag" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Super.new(parser, "super")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "super must be called from whithin a block tag"
      ) do
        tag.render(Marten::Template::Context.new)
      end
    end
  end
end
