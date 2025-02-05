require "./spec_helper"

describe Marten::Template::Tag::Capture do
  describe "::new" do
    it "can initialize a regular capture tag" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          Hello World, <b>{{ name }}</b>!
          {% endcapture %}
          TEMPLATE
      )

      tag = Marten::Template::Tag::Capture.new(parser, "capture my_var")

      context = Marten::Template::Context{"name" => "John Doe"}
      tag.render(context).should be_empty

      context["my_var"].should eq "Hello World, <b>John Doe</b>!\n"
    end

    it "can initialize a capture tag making use of the 'unless defined' modifier" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          Hello World, <b>{{ name }}</b>!
          {% endcapture %}
          TEMPLATE
      )

      tag = Marten::Template::Tag::Capture.new(parser, "capture my_var unless defined")

      context = Marten::Template::Context{"name" => "John Doe"}
      tag.render(context).should be_empty

      context["my_var"].should eq "Hello World, <b>John Doe</b>!\n"
    end

    it "raises a syntax error if no variable name is given" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          Hello World, <b>{{ name }}</b>!
          {% endcapture %}
          TEMPLATE
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed capture tag: one variable name must be specified."
      ) do
        Marten::Template::Tag::Capture.new(parser, "capture")
      end
    end

    it "raises a syntax error if more than one variable name is given" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          Hello World, <b>{{ name }}</b>!
          {% endcapture %}
          TEMPLATE
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed capture tag: unrecognized syntax."
      ) do
        Marten::Template::Tag::Capture.new(parser, "capture my_var my_var2 my_var3 my_var4")
      end
    end
  end

  describe "#render" do
    it "returns an empty string and assigns the captured content to the specified variable" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          Hello World, <b>{{ name }}</b>!
          {% endcapture %}
          TEMPLATE
      )

      tag = Marten::Template::Tag::Capture.new(parser, "capture my_var")

      context = Marten::Template::Context{"name" => "John Doe"}
      tag.render(context).should be_empty

      context["my_var"].should eq "Hello World, <b>John Doe</b>!\n"
    end

    it "returns an empty string and assigns the captured content to the specified variable even if it already exists" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          Hello World, <b>{{ name }}</b>!
          {% endcapture %}
          TEMPLATE
      )

      tag = Marten::Template::Tag::Capture.new(parser, "capture my_var")

      context = Marten::Template::Context{"name" => "John Doe", "my_var" => "Existing variable"}
      tag.render(context).should be_empty

      context["my_var"].should eq "Hello World, <b>John Doe</b>!\n"
    end

    it "does the assignment when the 'unless defined' modifier is used and the variable does not exist" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          Hello World, <b>{{ name }}</b>!
          {% endcapture %}
          TEMPLATE
      )

      tag = Marten::Template::Tag::Capture.new(parser, "capture my_var unless defined")

      context = Marten::Template::Context{"name" => "John Doe"}
      tag.render(context).should be_empty

      context["my_var"].should eq "Hello World, <b>John Doe</b>!\n"
    end

    it "does not do the assignment when the 'unless defined' modifier is used and the variable already exists" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          Hello World, <b>{{ name }}</b>!
          {% endcapture %}
          TEMPLATE
      )

      tag = Marten::Template::Tag::Capture.new(parser, "capture my_var unless defined")

      context = Marten::Template::Context{"name" => "John Doe", "my_var" => "Existing variable"}
      tag.render(context).should be_empty

      context["my_var"].should eq "Existing variable"
    end
  end
end
