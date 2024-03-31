require "./spec_helper"

describe Marten::Template::Tag::Assign do
  describe "::new" do
    it "can initialize a regular assign tag as expected" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::Assign.new(parser, "assign val1 = 'Hello'")

      context = Marten::Template::Context.new
      tag.render(context).should be_empty

      context["val1"].should eq "Hello"
    end

    it "can initialize an assign tag making use of the 'unless defined' modifier" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::Assign.new(parser, "assign val1 = nil unless defined")

      context = Marten::Template::Context.new
      tag.render(context).should be_empty

      context["val1"].raw.should be_nil
    end

    it "raises as expected if there are no assignments in the tag" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed assign tag: one assignment must be specified"
      ) do
        Marten::Template::Tag::Assign.new(parser, "assign")
      end
    end

    it "raises as expected if there are more than one assignment in the tag" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed assign tag: only one assignment must be specified"
      ) do
        Marten::Template::Tag::Assign.new(parser, "assign val1=1, val2=2")
      end
    end

    it "raises as expected if the 'unless defined' modifier is followed by other values" do
      parser = Marten::Template::Parser.new("")

      expect_raises(Marten::Template::Errors::InvalidSyntax) do
        Marten::Template::Tag::Assign.new(parser, "assign val1=1 unless defined foo bar")
      end
    end
  end

  describe "#render" do
    it "inserts a static value in the context" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::Assign.new(parser, "assign val1 = 'Hello world'")

      context = Marten::Template::Context.new
      tag.render(context).should be_empty

      context["val1"].should eq "Hello world"
    end

    it "inserts a dynamic value in the context" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::Assign.new(parser, "assign val1 = var|upcase")

      context = Marten::Template::Context{"var" => "Hello"}
      tag.render(context).should be_empty

      context["val1"].should eq "HELLO"
    end

    it "inserts the variable if it is not defined already when using the 'unless defined' modifier" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::Assign.new(parser, "assign val1 = var|upcase unless defined")

      context = Marten::Template::Context{"var" => "Hello"}
      tag.render(context).should be_empty

      context["val1"].should eq "HELLO"
    end

    it "does not insert the variable if it is already defined when using the 'unless defined' modifier" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::Assign.new(parser, "assign val1 = var|upcase unless defined")

      context = Marten::Template::Context{"var" => "Hello", "val1" => "other"}
      tag.render(context).should be_empty

      context["val1"].should eq "other"
    end
  end
end
