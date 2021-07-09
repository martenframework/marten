require "./spec_helper"

describe Marten::DB::Index do
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

  describe "#to_management_index" do
    it "returns the management version of the index" do
      index = Marten::DB::Index.new("new_index", fields: [Post.get_field("author"), Post.get_field("title")])
      management_index = index.to_management_index
      management_index.name.should eq "new_index"
      management_index.column_names.should eq ["author_id", "title"]
    end

    it "raises if a field does not have an associated database column" do
      index = Marten::DB::Index.new("new_index", fields: [TestUser.get_field("tags"), TestUser.get_field("email")])
      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Field 'tags' cannot be used as part of an index because it is not associated with a database column"
      ) do
        index.to_management_index
      end
    end
  end
end
