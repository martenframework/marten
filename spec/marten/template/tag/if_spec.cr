require "./spec_helper"

describe Marten::Template::Tag::If do
  describe "::new" do
    it "raises if the if block is not closed as expected" do
      parser = Marten::Template::Parser.new(
        "{% if var1 || var2 %}Hello?"
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unclosed tags, expected: elsif, else, endif"
      ) do
        Marten::Template::Tag::If.new(parser, "if var1 || var2")
      end
    end
  end

  describe "#render" do
    it "properly renders a simple if condition" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        It works!
        {% endif %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::If.new(parser, "if var1 || var2")

      tag.render(Marten::Template::Context{"var1" => true, "var2" => false}).strip.should eq "It works!"
      tag.render(Marten::Template::Context{"var1" => false, "var2" => false}).strip.should eq ""
    end

    it "properly renders a simple if/else condition" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        It works!
        {% else %}
        It also works!
        {% endif %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::If.new(parser, "if var1 || var2")

      tag.render(Marten::Template::Context{"var1" => true, "var2" => false}).strip.should eq "It works!"
      tag.render(Marten::Template::Context{"var1" => false, "var2" => false}).strip.should eq "It also works!"
    end

    it "properly renders a simple if/elsif/else condition" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        It works!
        {% elsif var1 %}
        Var 1 is set
        {% elsif var2 %}
        Var 2 is set
        {% else %}
        No vars set
        {% endif %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::If.new(parser, "if var1 && var2")

      tag.render(Marten::Template::Context{"var1" => true, "var2" => true}).strip.should eq "It works!"
      tag.render(Marten::Template::Context{"var1" => true, "var2" => false}).strip.should eq "Var 1 is set"
      tag.render(Marten::Template::Context{"var1" => false, "var2" => true}).strip.should eq "Var 2 is set"
      tag.render(Marten::Template::Context{"var1" => false, "var2" => false}).strip.should eq "No vars set"
    end
  end
end
