require "./spec_helper"

describe Marten::Template::NodeSet do
  describe "#add" do
    it "adds a node to the node set" do
      node_set = Marten::Template::NodeSet.new

      node_1 = Marten::Template::Node::Text.new("Hello World!")
      node_2 = Marten::Template::Node::Text.new("\n")

      node_set.add(node_1)
      node_set.add(node_2)

      node_set.to_a.should eq [node_1, node_2]
    end
  end

  describe "#each" do
    it "allows to iterate over the node set's nodes" do
      node_set = Marten::Template::NodeSet.new

      node_1 = Marten::Template::Node::Text.new("Hello World!")
      node_2 = Marten::Template::Node::Text.new("\n")

      node_set.add(node_1)
      node_set.add(node_2)

      node_set.each.to_a.should eq [node_1, node_2]
    end
  end

  describe "#render" do
    it "returns a string containing all the underlying rendered nodes outputs" do
      node_set = Marten::Template::NodeSet.new

      node_1 = Marten::Template::Node::Text.new("Hello World!")
      node_2 = Marten::Template::Node::Text.new("\n")

      node_set.add(node_1)
      node_set.add(node_2)

      node_set.render(Marten::Template::Context.new).should eq "Hello World!\n"
    end
  end
end
