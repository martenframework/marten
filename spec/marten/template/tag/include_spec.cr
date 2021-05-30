require "./spec_helper"

describe Marten::Template::Tag::Include do
  describe "::new" do
    it "can initialize a regular include tag as expected" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Include.new(parser, %{include "partials/hello_world.html"})
      tag.render(Marten::Template::Context{"name" => "John Doe"}).includes?("Hello World, John Doe!").should be_true
    end

    it "raises if not enough parameters are specified" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed include tag: at least one argument must be provided (template name to include)"
      ) do
        Marten::Template::Tag::Include.new(parser, %{include})
      end
    end

    it "raises if the third argument is not the with keyword" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed include tag: 'with' keyword expected to define variable assignments"
      ) do
        Marten::Template::Tag::Include.new(parser, %{include "test.html" foo})
      end
    end

    it "raises if the with keyword is the last argument being used" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed include tag: the 'with' keyword must be followed by variable assignments"
      ) do
        Marten::Template::Tag::Include.new(parser, %{include "test.html" with})
      end
    end

    it "raises if the a variable is assigned more than once" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed include tag: 'val1' variable defined more than once"
      ) do
        Marten::Template::Tag::Include.new(parser, %{include "test.html" with val1=var1, val2=var2, val1="other"})
      end
    end
  end

  describe "#render" do
    it "renders an include tag whose variables are already in the context" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::Include.new(parser, %{include "partials/hello_world.html"})
      tag.render(Marten::Template::Context{"name" => "John Doe"}).includes?("Hello World, John Doe!").should be_true
    end

    it "renders an include tag whose variables are defined as part of the tag" do
      parser = Marten::Template::Parser.new("")

      tag_1 = Marten::Template::Tag::Include.new(parser, %{include "partials/hello_world.html" with name="John Doe"})
      tag_1.render(Marten::Template::Context.new).includes?("Hello World, John Doe!").should be_true

      tag_2 = Marten::Template::Tag::Include.new(parser, %{include "partials/hello_world.html" with name=name_var})
      tag_2.render(Marten::Template::Context{"name_var" => "John Doe"})
        .includes?("Hello World, John Doe!").should be_true
    end

    it "renders an include tag whose template name is defined as a variable" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::Include.new(parser, %{include include_tpl_name})
      tag.render(Marten::Template::Context{"include_tpl_name" => "partials/hello_world.html", "name" => "John Doe"})
        .includes?("Hello World, John Doe!").should be_true
    end

    it "does not leak include variables in the outer context" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Include.new(parser, %{include "partials/hello_world.html" with name="John Doe"})

      ctx = Marten::Template::Context.new
      tag.render(ctx).includes?("Hello World, John Doe!").should be_true
      ctx["name"]?.should be_nil
    end

    it "raises if the include template name does not resolve to a string" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Include.new(parser, %{include include_tpl_name})

      expect_raises(
        Marten::Template::Errors::UnsupportedValue,
        "Template name name must resolve to a string, got a Int32 object"
      ) do
        tag.render(Marten::Template::Context{"include_tpl_name" => 42, "name" => "John Doe"})
      end
    end
  end
end
