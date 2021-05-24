require "./spec_helper"

describe Marten::Template::Tag::Extend do
  describe "::new" do
    it "can initialize a regular extend tag as expected" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Extend.new(parser, %{extend "base.html"})
      tag.render(Marten::Template::Context.new).should_not be_empty
    end

    it "raises if the extend tag does not define a template name" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed extend tag: one argument must be provided"
      ) do
        Marten::Template::Tag::Extend.new(parser, "extend")
      end
    end

    it "raises if the extend tag contains more than the template name argument" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed extend tag: only one argument must be provided"
      ) do
        Marten::Template::Tag::Extend.new(parser, %{extend "base.html" other})
      end
    end

    it "raises if other extend tags are defined within the parsed nodes" do
      parser = Marten::Template::Parser.new("{% extend 'base.html' %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Only one extend tag is allowed per template"
      ) do
        Marten::Template::Tag::Extend.new(parser, %{extend "base.html"})
      end
    end
  end

  describe "#render" do
    it "renders the parent template with the block overrides of the current template" do
      parser = Marten::Template::Parser.new("{% block title %}Local title{% endblock %}")
      tag = Marten::Template::Tag::Extend.new(parser, %{extend "base.html"})
      tag.render(Marten::Template::Context.new).includes?("<title>Local title</title>").should be_true
    end

    it "can resolve a template name from a variable" do
      parser = Marten::Template::Parser.new("{% block title %}Local title{% endblock %}")
      tag = Marten::Template::Tag::Extend.new(parser, "extend tpl_name")
      tag.render(Marten::Template::Context{"tpl_name" => "base.html"}).includes?("<title>Local title</title>").should(
        be_true
      )
    end

    it "raises an error if template name variable resolves to a non-string value" do
      parser = Marten::Template::Parser.new("{% block title %}Local title{% endblock %}")
      tag = Marten::Template::Tag::Extend.new(parser, "extend tpl_name")
      expect_raises(
        Marten::Template::Errors::UnsupportedValue,
        "Template parent name must resolve to a string, got a Int32 object"
      ) do
        tag.render(Marten::Template::Context{"tpl_name" => 42})
      end
    end
  end
end
