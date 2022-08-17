require "./spec_helper"

describe Marten::Template::Parser do
  around_each do |t|
    original_debug = Marten.settings.debug
    t.run
    Marten.settings.debug = original_debug
  end

  describe "#encountered_block_names" do
    it "returns an empty array by default" do
      parser = Marten::Template::Parser.new("Hello!")
      parser.encountered_block_names.should be_empty
      parser.parse
      parser.encountered_block_names.should be_empty
    end

    it "returns an array containing the encountered blocks if the template source contains blocks" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {% block title %}
        Hello
        {% endblock title %}

        {% block body %}
        Hello
        {% endblock body %}
        TEMPLATE
      )

      parser.parse
      parser.encountered_block_names.should eq ["title", "body"]
    end
  end

  describe "#parse" do
    it "returns the node set corresponding to the parsed template" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        Hello World, {{ name }}!
        {% if var %}Foo Bar{% endif %}
        TEMPLATE
      )

      node_set = parser.parse

      node_set.should be_a Marten::Template::NodeSet
      node_set.to_a[0].should be_a Marten::Template::Node::Text
      node_set.to_a[1].should be_a Marten::Template::Node::Variable
      node_set.to_a[2].should be_a Marten::Template::Node::Text
      node_set.to_a[3].should be_a Marten::Template::Node::Tag
    end

    it "raises if an empty variable is detected" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        Hello World, {{ }}!
        TEMPLATE
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Empty variable detected on line 1"
      ) do
        parser.parse
      end
    end

    it "raises if an empty tag is detected" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        Hello World, {% %}!
        TEMPLATE
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Empty tag detected on line 1"
      ) do
        parser.parse
      end
    end

    it "raises if an end tag is expected" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        Hello World!
        TEMPLATE
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unclosed tags, expected: endif, else, elsif"
      ) do
        parser.parse(up_to: ["endif", "else", "elsif"])
      end
    end

    it "properly decorates invalid syntax errors when in debug mode" do
      with_overridden_setting(:debug, true) do
        source = <<-TEMPLATE
        Hello World, {% %}!
        TEMPLATE

        parser = Marten::Template::Parser.new(source)

        error = expect_raises(
          Marten::Template::Errors::InvalidSyntax,
          "Empty tag detected on line 1"
        ) do
          parser.parse
        end

        error.source.should eq source
        error.token.not_nil!.type.should eq Marten::Template::Parser::TokenType::TAG
      end
    end

    it "does not decorate invalid syntax errors when not in debug mode" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        Hello World, {% %}!
        TEMPLATE
      )

      error = expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Empty tag detected on line 1"
      ) do
        parser.parse
      end

      error.source.should be_nil
      error.token.should be_nil
    end
  end

  describe "#shift_token" do
    it "allows to explicitly shift tokens" do
      parser = Marten::Template::Parser.new("{{ prefix }} Hello World, {{ var }}!")

      shifted_token = parser.shift_token.not_nil!
      shifted_token.type.should eq Marten::Template::Parser::TokenType::VARIABLE
      shifted_token.content.should eq "prefix"

      node_set = parser.parse
      node_set.to_a[0].should be_a Marten::Template::Node::Text
      node_set.to_a[1].should be_a Marten::Template::Node::Variable
      node_set.to_a[2].should be_a Marten::Template::Node::Text
    end
  end
end
