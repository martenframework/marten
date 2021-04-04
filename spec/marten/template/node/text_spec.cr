require "./spec_helper"

describe Marten::Template::Node::Text do
  describe "#render" do
    it "returns the unaltered text string" do
      ctx = Marten::Template::Context.new

      node_1 = Marten::Template::Node::Text.new("Hello World!")
      node_1.render(ctx).should eq "Hello World!"

      node_2 = Marten::Template::Node::Text.new("\n")
      node_2.render(ctx).should eq "\n"
    end
  end
end
