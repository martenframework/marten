require "./spec_helper"

describe Marten::Template::Node::Variable do
  describe "#render" do
    it "returns the string representation of the variable resolved using the current context" do
      ctx = Marten::Template::Context{
        "foo" => "bar",
        "user" => { "name" => "John Doe" }
      }

      node_1 = Marten::Template::Node::Variable.new("foo")
      node_1.render(ctx).should eq "bar"

      node_2 = Marten::Template::Node::Variable.new("user.name")
      node_2.render(ctx).should eq "John Doe"
    end
  end
end
