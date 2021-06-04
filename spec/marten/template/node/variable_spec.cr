require "./spec_helper"

describe Marten::Template::Node::Variable do
  describe "#render" do
    it "returns the string representation of the variable resolved using the current context" do
      ctx = Marten::Template::Context{
        "foo"  => "bar",
        "user" => {"name" => "John Doe"},
      }

      node_1 = Marten::Template::Node::Variable.new("foo")
      node_1.render(ctx).should eq "bar"

      node_2 = Marten::Template::Node::Variable.new("user.name")
      node_2.render(ctx).should eq "John Doe"
    end

    it "returns the string representation of a variable involving filter lookups" do
      ctx = Marten::Template::Context{
        "foo"  => "bar",
        "user" => {"name" => "John Doe"},
      }

      node_1 = Marten::Template::Node::Variable.new("foo|upcase")
      node_1.render(ctx).should eq "BAR"

      node_2 = Marten::Template::Node::Variable.new("user.name|upcase")
      node_2.render(ctx).should eq "JOHN DOE"
    end

    it "automatically escape values" do
      ctx = Marten::Template::Context{"body" => "<div>Hello</div>"}

      node = Marten::Template::Node::Variable.new("body")
      node.render(ctx).should eq "&lt;div&gt;Hello&lt;/div&gt;"
    end

    it "does not escape safe strings" do
      ctx = Marten::Template::Context{"body" => Marten::Template::SafeString.new("<div>Hello</div>")}

      node = Marten::Template::Node::Variable.new("body")
      node.render(ctx).should eq "<div>Hello</div>"
    end
  end
end
