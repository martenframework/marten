require "./spec_helper"

describe Marten::Template::Tag::Escape do
  describe "::new" do
    it "can initialize a regular 'escape on' tag" do
      parser = Marten::Template::Parser.new("Example{% endescape %}")

      tag = Marten::Template::Tag::Escape.new(parser, "escape on")
      tag.should be_a Marten::Template::Tag::Escape
    end

    it "can initialize a regular 'escape off' tag" do
      parser = Marten::Template::Parser.new("Example{% endescape %}")

      tag = Marten::Template::Tag::Escape.new(parser, "escape off")
      tag.should be_a Marten::Template::Tag::Escape
    end

    it "raises if no argument is given" do
      parser = Marten::Template::Parser.new("Example{% endescape %}")

      expect_raises(Marten::Template::Errors::InvalidSyntax, "Malformed escape tag: one argument must be provided") do
        Marten::Template::Tag::Escape.new(parser, "escape")
      end
    end

    it "raises if too many arguments are provided" do
      parser = Marten::Template::Parser.new("Example{% endescape %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed escape tag: only one argument must be provided"
      ) do
        Marten::Template::Tag::Escape.new(parser, "escape on off")
      end
    end

    it "raises if the single argument is invalid" do
      parser = Marten::Template::Parser.new("Example{% endescape %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed escape tag: the argument must be either on or off"
      ) do
        Marten::Template::Tag::Escape.new(parser, "escape bad")
      end
    end
  end

  describe "#render" do
    it "escapes the content if escape is on" do
      parser = Marten::Template::Parser.new("{{ foo }}{% endescape %}")
      tag = Marten::Template::Tag::Escape.new(parser, "escape on")

      context = Marten::Template::Context{"foo" => "<p>bar</p>"}

      tag.render(context).should eq "&lt;p&gt;bar&lt;/p&gt;"
    end

    it "does not escape the content if escape is off" do
      parser = Marten::Template::Parser.new("{{ foo }}{% endescape %}")
      tag = Marten::Template::Tag::Escape.new(parser, "escape off")

      context = Marten::Template::Context{"foo" => "<p>bar</p>"}

      tag.render(context).should eq "<p>bar</p>"
    end
  end
end
