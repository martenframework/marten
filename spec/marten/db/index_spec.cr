require "./spec_helper"

describe Marten::DB::Index do
  describe "#clone" do
    it "clones the index" do
      index = Marten::DB::Index.new(name: "new_index", fields: [Post.get_field("author"), Post.get_field("title")])
      cloned_index = index.clone

      cloned_index.should_not be index
      cloned_index.name.should eq index.name
      cloned_index.fields.should eq index.fields
    end
  end

  describe "#name" do
    it "returns the index name" do
      index = Marten::DB::Index.new("new_index", fields: [Post.get_field("author"), Post.get_field("title")])
      index.name.should eq "new_index"
    end
  end

  describe "#fields" do
    it "returns the index fields" do
      index = Marten::DB::Index.new("new_index", fields: [Post.get_field("author"), Post.get_field("title")])
      index.fields.should eq [Post.get_field("author"), Post.get_field("title")]
    end
  end
end
