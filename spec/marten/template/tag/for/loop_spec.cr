require "./spec_helper"

describe Marten::Template::Tag::For::Loop do
  describe "#first?" do
    it "returns true if the loop is at the first item" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)
      loop.index = 0
      loop.first?.should be_true
    end

    it "returns false if the loop is not at the first item" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)
      loop.index = 1
      loop.first?.should be_false
    end
  end

  describe "#index" do
    it "returns the current loop index (starting at 1)" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)
      loop.index = 0
      loop.index.should eq 1
    end
  end

  describe "#index=" do
    it "allows to set the current loop index" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)

      loop.index = 0

      loop.index.should eq 1
      loop.index0.should eq 0

      loop.index = 3

      loop.index.should eq 4
      loop.index0.should eq 3
    end
  end

  describe "#index0" do
    it "returns the current loop index (starting at 0)" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)
      loop.index = 0
      loop.index0.should eq 0
    end
  end

  describe "#last?" do
    it "returns true if the loop is at the last item" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)
      loop.index = 9
      loop.last?.should be_true
    end

    it "returns false if the loop is not at the last item" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)
      loop.index = 1
      loop.last?.should be_false
    end
  end

  describe "#parent" do
    it "returns nil by default" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)
      loop.index = 0

      loop.parent.should be_nil
    end

    it "returns the parent loop template value if set accordingly" do
      parent_value = Marten::Template::Value.from(Marten::Template::Tag::For::Loop.new(items_size: 10))

      loop = Marten::Template::Tag::For::Loop.new(items_size: 10, parent: parent_value)

      loop.parent.should eq parent_value
    end
  end

  describe "#revindex" do
    it "returns the current loop reverse index (ending at 1)" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)

      loop.index = 0
      loop.revindex.should eq 10

      loop.index = 1
      loop.revindex.should eq 9
    end
  end

  describe "#revindex0" do
    it "returns the current loop reverse index (ending at à0)" do
      loop = Marten::Template::Tag::For::Loop.new(items_size: 10)

      loop.index = 0
      loop.revindex0.should eq 9

      loop.index = 1
      loop.revindex0.should eq 8
    end
  end
end
