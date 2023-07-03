require "./spec_helper"

describe Marten::Template::Tag::With do
  describe "::new" do
    it "raises if the with block does not contain at least one assignment" do
      parser = Marten::Template::Parser.new(
        "test{% endwith %}"
      )

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed with tag:at least one assignment must be present"
      ) do
        Marten::Template::Tag::With.new(parser, "with x")
      end
    end
  end

  describe "#render" do
    it "properly renders a simple with block" do
      parser = Marten::Template::Parser.new(
        <<-TEMPLATE
          {{ x }}
          {% endwith %}
          TEMPLATE
      )
      tag = Marten::Template::Tag::With.new(parser, "with x=1")

      tag.render(Marten::Template::Context.new).strip.should eq "1"
    end
  end

  it "properly renders with multiple variables assigned" do
    parser = Marten::Template::Parser.new(
      <<-TEMPLATE
          {{ x }} - {{ y }}
          {% endwith %}
          TEMPLATE
    )
    tag = Marten::Template::Tag::With.new(parser, "with x=1, y=2")

    tag.render(Marten::Template::Context.new).strip.should eq "1 - 2"
  end

  it "does not pollute the outer context with local variables" do
    parser = Marten::Template::Parser.new(
      <<-TEMPLATE
          {{ x }} - {{ y }}
          {% endwith %}
          TEMPLATE
    )

    context = Marten::Template::Context.new
    tag = Marten::Template::Tag::With.new(parser, "with x=1, y=2")

    tag.render(context)

    context["x"]?.should eq nil
    context["y"]?.should eq nil
  end

  it "use context variables as value" do
    parser = Marten::Template::Parser.new(
      <<-TEMPLATE
          {{ x }}
          {% endwith %}
          TEMPLATE
    )

    tag = Marten::Template::Tag::With.new(parser, "with x = var")

    context = Marten::Template::Context{"var" => "2"}
    tag.render(context).strip.should eq "2"
  end

  it "shadows existing variables" do
    parser = Marten::Template::Parser.new("")

    context = Marten::Template::Context.new
    Marten::Template::Tag::Assign.new(parser, "assign x = 'test'").render(context)

    context["x"].should eq "test"

    parser = Marten::Template::Parser.new(
      <<-TEMPLATE
          {{ y }} - {{ x }}
          {% endwith %}
          TEMPLATE
    )

    tag = Marten::Template::Tag::With.new(parser, "with y = x, x = 1")
    tag.render(context).strip.should eq "test - 1"

    context["x"].should eq "test"
  end

  it "order of assignments has an impact" do
    context = Marten::Template::Context{"x" => "test"}

    parser = Marten::Template::Parser.new(
      <<-TEMPLATE
          {{ y }} - {{ x }}
          {% endwith %}
          TEMPLATE
    )

    tag = Marten::Template::Tag::With.new(parser, "with x = 1, y = x")
    tag.render(context).strip.should_not eq "test - 1"
  end
end
