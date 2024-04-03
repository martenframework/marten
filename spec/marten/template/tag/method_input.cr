require "./spec_helper"

describe Marten::Template::Tag::MethodInput do
  describe "::new" do
    it "raises if the method_input tag does not contain one argument" do
      parser = Marten::Template::Parser.new("{% method_input %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed method_input tag: exactly one argument must be provided"
      ) do
        Marten::Template::Tag::MethodInput.new(parser, "method_input")
      end
    end

    it "raises if the method_input tag contains more than one argument" do
      parser = Marten::Template::Parser.new("{% method_input 'DELETE' other args %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed method_input tag: exactly one argument must be provided"
      ) do
        Marten::Template::Tag::MethodInput.new(parser, "method_input 'DELETE' other args")
      end
    end
  end

  describe "#render" do
    it "returns an HTML input tag with the specified method" do
      parser = Marten::Template::Parser.new("")

      tag_1 = Marten::Template::Tag::MethodInput.new(parser, %{method_input 'DELETE'})
      tag_1.render(Marten::Template::Context.new).should eq %(<input type="hidden" name="_method" value="DELETE">)

      tag_2 = Marten::Template::Tag::MethodInput.new(parser, %{method_input 'PUT'})
      tag_2.render(Marten::Template::Context.new).should eq %(<input type="hidden" name="_method" value="PUT">)
    end
  end
end
