require "./spec_helper"

describe Marten::DB::Management::Index do
  describe "::from" do
    it "returns the management version of the index" do
      index = Marten::DB::Index.new("new_index", fields: [Post.get_field("author"), Post.get_field("title")])
      management_index = Marten::DB::Management::Index.from(index)
      management_index.name.should eq "new_index"
      management_index.column_names.should eq ["author_id", "title"]
    end

    it "raises if a field does not have an associated database column" do
      index = Marten::DB::Index.new("new_index", fields: [TestUser.get_field("tags"), TestUser.get_field("email")])
      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Field 'tags' cannot be used as part of an index because it is not associated with a database column"
      ) do
        Marten::DB::Management::Index.from(index)
      end
    end
  end

  describe "::new" do
    it "allows to initialize an index from a name and column names strings" do
      index = Marten::DB::Management::Index.new("new_index", column_names: ["author_id", "title"])
      index.name.should eq "new_index"
      index.column_names.should eq ["author_id", "title"]
    end

    it "allows to initialize an index from a name and column names symbols" do
      index = Marten::DB::Management::Index.new(:new_index, column_names: [:author_id, :title])
      index.name.should eq "new_index"
      index.column_names.should eq ["author_id", "title"]
    end
  end

  describe "#==" do
    it "returns true if the other object is the same object" do
      index = Marten::DB::Management::Index.new(:new_index, column_names: [:author_id, :title])
      other_index = index

      other_index.should eq index
    end

    it "returns true if the other objects corresponds to the same index configuration" do
      Marten::DB::Management::Index.new(:new_index, column_names: [:author_id, :title]).should eq(
        Marten::DB::Management::Index.new(:new_index, column_names: [:author_id, :title])
      )
    end

    it "returns true if the column names of the other objects are ordered differently" do
      Marten::DB::Management::Index.new(:new_index, column_names: [:author_id, :title]).should eq(
        Marten::DB::Management::Index.new(:new_index, column_names: [:title, :author_id])
      )
    end

    it "returns false if the other index has a different name" do
      Marten::DB::Management::Index.new(:new_index, column_names: [:author_id, :title]).should_not eq(
        Marten::DB::Management::Index.new(:other_index, column_names: [:author_id, :title])
      )
    end

    it "returns false if the other index has not the same columns names" do
      Marten::DB::Management::Index.new(:new_index, column_names: [:author_id, :title]).should_not eq(
        Marten::DB::Management::Index.new(:new_index, column_names: [:author_id])
      )
    end
  end

  describe "#name" do
    it "returns the index name" do
      index = Marten::DB::Management::Index.new("new_index", column_names: ["author_id", "title"])
      index.name.should eq "new_index"
    end
  end

  describe "#column_names" do
    it "returns the index column names" do
      index = Marten::DB::Management::Index.new("new_index", column_names: ["author_id", "title"])
      index.column_names.should eq ["author_id", "title"]
    end
  end

  describe "#clone" do
    it "clones the considered index" do
      index = Marten::DB::Management::Index.new("new_index", column_names: ["author_id", "title"])
      cloned_index = index.clone

      cloned_index.should_not be index
      cloned_index.name.should eq index.name
      cloned_index.column_names.should eq index.column_names
      cloned_index.column_names.should_not be index.column_names
    end
  end

  describe "#serialize_args" do
    it "returns a serialized version of the index arguments" do
      index = Marten::DB::Management::Index.new("new_index", column_names: ["author_id", "title"])
      index.serialize_args.should eq %{:new_index, [:author_id, :title]}
    end
  end
end
