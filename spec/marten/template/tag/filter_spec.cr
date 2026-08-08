require "./spec_helper"

describe Marten::Template::Tag::Filter do
  describe "::new" do
    it "raises if no filter is given" do
      parser = Marten::Template::Parser.new("Hello{% endfilter %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed filter tag: at least one argument must be provided"
      ) do
        Marten::Template::Tag::Filter.new(parser, "filter")
      end
    end

    it "raises if the block is not closed as expected" do
      parser = Marten::Template::Parser.new("Hello {{ name }}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unclosed tags, expected: endfilter"
      ) do
        Marten::Template::Tag::Filter.new(parser, "filter upcase")
      end
    end

    it "raises if the escape filter is used" do
      parser = Marten::Template::Parser.new("Hello{% endfilter %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        %("filter escape" is not permitted. Use the "escape" tag instead.)
      ) do
        Marten::Template::Tag::Filter.new(parser, "filter escape")
      end
    end

    it "raises if the safe filter is used" do
      parser = Marten::Template::Parser.new("Hello{% endfilter %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        %("filter safe" is not permitted. Use the "escape" tag instead.)
      ) do
        Marten::Template::Tag::Filter.new(parser, "filter safe")
      end
    end

    it "raises if a forbidden filter is used in a chain" do
      parser = Marten::Template::Parser.new("Hello{% endfilter %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        %("filter escape" is not permitted. Use the "escape" tag instead.)
      ) do
        Marten::Template::Tag::Filter.new(parser, "filter upcase|escape")
      end
    end
  end

  describe "#render" do
    it "applies a single filter to the block content" do
      parser = Marten::Template::Parser.new("Hello {{ name }}!{% endfilter %}")
      tag = Marten::Template::Tag::Filter.new(parser, "filter upcase")

      tag.render(Marten::Template::Context{"name" => "John"}).should eq "HELLO JOHN!"
    end

    it "applies multiple chained filters to the block content" do
      parser = Marten::Template::Parser.new("Hello {{ name }}!{% endfilter %}")
      tag = Marten::Template::Tag::Filter.new(parser, "filter upcase|truncate:8")

      tag.render(Marten::Template::Context{"name" => "John"}).should eq "HELLO..."
    end

    it "supports spaces around filter pipes" do
      parser = Marten::Template::Parser.new("Hello {{ name }}!{% endfilter %}")
      tag = Marten::Template::Tag::Filter.new(parser, "filter upcase | truncate:8")

      tag.render(Marten::Template::Context{"name" => "John"}).should eq "HELLO..."
    end

    it "supports filters with arguments" do
      parser = Marten::Template::Parser.new("{{ name }}{% endfilter %}")
      tag = Marten::Template::Tag::Filter.new(parser, "filter default:'Anonymous'")

      tag.render(Marten::Template::Context{"name" => nil}).should eq "Anonymous"
    end

    it "renders nested variables inside the block" do
      parser = Marten::Template::Parser.new("{{ user.name }}{% endfilter %}")
      tag = Marten::Template::Tag::Filter.new(parser, "filter upcase")

      tag.render(Marten::Template::Context{"user" => {"name" => "John"}}).should eq "JOHN"
    end

    it "does not leak the temporary filter variable into the outer context" do
      parser = Marten::Template::Parser.new("Hello{% endfilter %}")
      tag = Marten::Template::Tag::Filter.new(parser, "filter upcase")

      context = Marten::Template::Context.new
      tag.render(context)

      context["v"]?.should be_nil
    end
  end
end
