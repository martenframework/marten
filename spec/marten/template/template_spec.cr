require "./spec_helper"

describe Marten::Template::Template do
  describe "#nodes" do
    it "returns the nodes of the template" do
      template = Marten::Template::Template.new("{% if answer == 42 %}ok{% endif %}")
      template.nodes.should be_a Marten::Template::NodeSet
      template.nodes.size.should eq 1
      template.nodes.first.as(Marten::Template::Node::Tag).tag.should be_a Marten::Template::Tag::If
    end
  end

  describe "#render" do
    it "can render a template from without a context" do
      template = Marten::Template::Template.new("Hello!")
      template.render.should eq "Hello!"
    end

    it "can render a template from a given context" do
      template = Marten::Template::Template.new("{% if answer == 42 %}ok{% endif %}")
      template.render(Marten::Template::Context{"answer" => 42}).should eq "ok"
    end

    it "can render a template from a given context hash" do
      template = Marten::Template::Template.new("{% if answer == 42 %}ok{% endif %}")
      template.render({"answer" => 42}).should eq "ok"
    end

    it "can render a template from a given context named tuple" do
      template = Marten::Template::Template.new("{% if answer == 42 %}ok{% endif %}")
      template.render({answer: 42}).should eq "ok"
    end
  end
end
