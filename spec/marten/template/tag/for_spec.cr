require "./spec_helper"

describe Marten::Template::Tag::For do
  describe "::new" do
    it "raises if the for block does not contain enough words" do
      parser = Marten::Template::Parser.new(
        "{% for x %}test{% endfor %}"
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "For loops must have the following format: for x in y"
      ) do
        Marten::Template::Tag::For.new(parser, "for x")
      end
    end

    it "raises if the for block does not contain the in keyword at the expected position" do
      parser = Marten::Template::Parser.new(
        "{% for x bad y %}test{% endfor %}"
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "For loops must have the following format: for x in y"
      ) do
        Marten::Template::Tag::For.new(parser, "for x bad y")
      end
    end
  end

  describe "#render" do
    it "properly renders a simple for block" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {{ item }};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      tag.render(Marten::Template::Context{"arr" => ["foo", "bar"]}).strip.gsub("\n", "").should eq "foo;bar;"
      tag.render(Marten::Template::Context{"arr" => [] of String}).strip.should eq ""
    end

    it "properly renders a for block involving unpacking multiple iteration variables" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {{ x }}|{{ y }};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for x, y in h")

      rendered = tag.render(Marten::Template::Context{"h" => {"foo" => "bar", "xyz" => "test"}}).strip.gsub("\n", "")
      rendered.should eq "foo|bar;xyz|test;"
    end

    it "properly renders a simple for block with an else block" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {{ item }};
        {% else %}
        No item
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      tag.render(Marten::Template::Context{"arr" => ["foo", "bar"]}).strip.gsub("\n", "").should eq "foo;bar;"
      tag.render(Marten::Template::Context{"arr" => [] of String}).strip.should eq "No item"
    end

    it "properly renders a simple for block with an else block containing an if/else block" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {% if item == "foo" %}
        foo!
        {% else %}
        not foo!
        {% endif %}
        {% else %}
        No item
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      tag.render(Marten::Template::Context{"arr" => ["foo", "bar"]}).strip.gsub("\n", "").should eq "foo!not foo!"
      tag.render(Marten::Template::Context{"arr" => [] of String}).strip.should eq "No item"
    end

    it "exposes the index (starting at 1) of each iteration" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {{ loop.index }};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      tag.render(Marten::Template::Context{"arr" => ["foo", "bar", "test"]}).strip.gsub("\n", "").should eq "1;2;3;"
    end

    it "exposes the index (starting at 10) of each iteration" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {{ loop.index0 }};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      tag.render(Marten::Template::Context{"arr" => ["foo", "bar", "test"]}).strip.gsub("\n", "").should eq "0;1;2;"
    end

    it "exposes the reverse index (ending at 1) of each iteration" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {{ loop.revindex }};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      tag.render(Marten::Template::Context{"arr" => ["foo", "bar", "test"]}).strip.gsub("\n", "").should eq "3;2;1;"
    end

    it "exposes the reverse index (ending at 0) of each iteration" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {{ loop.revindex0 }};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      tag.render(Marten::Template::Context{"arr" => ["foo", "bar", "test"]}).strip.gsub("\n", "").should eq "2;1;0;"
    end

    it "exposes whether a specific iteration is the first one or not" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {% if loop.first? %}1{% else %}0{% endif %};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      tag.render(Marten::Template::Context{"arr" => ["foo", "bar", "test"]}).strip.gsub("\n", "").should eq "1;0;0;"
    end

    it "exposes whether a specific iteration is the last one or not" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {% if loop.last? %}1{% else %}0{% endif %};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      tag.render(Marten::Template::Context{"arr" => ["foo", "bar", "test"]}).strip.gsub("\n", "").should eq "0;0;1;"
    end

    it "exposes the parent loop information if applicable" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {% for sub_item in sub_arr %}
        {{ loop.parent.index }};
        {% endfor %}
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for item in arr")

      rendered = tag.render(
        Marten::Template::Context{"arr" => ["foo", "bar", "test"], "sub_arr" => [1, 2, 3]}
      ).strip.gsub("\n", "")
      rendered.should eq "1;1;1;2;2;2;3;3;3;"
    end

    it "raises if each iteration item cannot be unpacked into multiple variables" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {{ x }}|{{ y }};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for x, y in arr")

      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "Unable to unpack String objects into multiple variables"
      ) do
        tag.render(Marten::Template::Context{"arr" => ["foo", "bar"]})
      end
    end

    it "raises if there are missing variables to unpack" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
        {{ x }}|{{ y }};
        {% endfor %}
        TEMPLATE
      )
      tag = Marten::Template::Tag::For.new(parser, "for x, y, z in h")

      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "Missing objects to unpack"
      ) do
        tag.render(Marten::Template::Context{"h" => {"foo" => "bar", "xyz" => "test"}})
      end
    end
  end
end
