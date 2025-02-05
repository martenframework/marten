require "./spec_helper"

describe Marten::Template::Tag::Unless do
  describe "::new" do
    it "raises if the unless block is not closed as expected" do
      parser = Marten::Template::Parser.new(
        "{% unless var1 || var2 %}Hello?"
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unclosed tags, expected: else, endunless"
      ) do
        Marten::Template::Tag::Unless.new(parser, "unless var1 || var2")
      end
    end
  end

  describe "#render" do
    it "properly renders a simple unless condition" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          It works!
          {% endunless %}
          TEMPLATE
      )
      tag = Marten::Template::Tag::Unless.new(parser, "unless var1 || var2")

      tag.render(Marten::Template::Context{"var1" => true, "var2" => false}).strip.should eq ""
      tag.render(Marten::Template::Context{"var1" => false, "var2" => false}).strip.should eq "It works!"
    end

    it "properly renders a simple unless/else condition" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          It works!
          {% else %}
          It also works!
          {% endunless %}
          TEMPLATE
      )
      tag = Marten::Template::Tag::Unless.new(parser, "if var1 || var2")

      tag.render(Marten::Template::Context{"var1" => true, "var2" => false}).strip.should eq "It also works!"
      tag.render(Marten::Template::Context{"var1" => false, "var2" => false}).strip.should eq "It works!"
    end
  end
end
