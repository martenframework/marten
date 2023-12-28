require "./spec_helper"

describe Marten::DB::ReverseRelation do
  describe "#id" do
    it "returns the ID of the reverse relation" do
      reverse_relation = Marten::DB::ReverseRelation.new("posts", Post, "author_id")
      reverse_relation.id.should eq "posts"
    end
  end

  describe "#field_id" do
    it "returns the ID of the field that initiated the reverse relation" do
      reverse_relation = Marten::DB::ReverseRelation.new("posts", Post, "author_id")
      reverse_relation.field_id.should eq "author_id"
    end
  end

  describe "#model" do
    it "returns the model class targetted by the reverse relation" do
      reverse_relation = Marten::DB::ReverseRelation.new("posts", Post, "author_id")
      reverse_relation.model.should eq Post
    end
  end

  describe "#on_delete" do
    it "returns the deletion strategy for the associated field" do
      reverse_relation = Marten::DB::ReverseRelation.new("posts", Post, "author_id")
      reverse_relation.on_delete.should eq Marten::DB::Deletion::Strategy::CASCADE
    end
  end

  describe "#many_to_many?" do
    it "returns true if the associated field is a many-to-many field" do
      reverse_relation = Marten::DB::ReverseRelation.new("tagged_users", TestUser, "tags")
      reverse_relation.many_to_many?.should be_true
    end

    it "returns false if the associated field is not a many-to-one field" do
      reverse_relation = Marten::DB::ReverseRelation.new("profile", TestUserProfile, "user_id")
      reverse_relation.many_to_many?.should be_false
    end
  end

  describe "#many_to_one?" do
    it "returns true if the associated field is a many-to-one field" do
      reverse_relation = Marten::DB::ReverseRelation.new("posts", Post, "author_id")
      reverse_relation.many_to_one?.should be_true
    end

    it "returns false if the associated field is not a many-to-one field" do
      reverse_relation = Marten::DB::ReverseRelation.new("profile", TestUserProfile, "user_id")
      reverse_relation.many_to_one?.should be_false
    end
  end

  describe "#one_to_one?" do
    it "returns true if the associated field is a one-to-one field" do
      reverse_relation = Marten::DB::ReverseRelation.new("profile", TestUserProfile, "user_id")
      reverse_relation.one_to_one?.should be_true
    end

    it "returns false if the associated field is not a one-to-one field" do
      reverse_relation = Marten::DB::ReverseRelation.new("posts", Post, "author_id")
      reverse_relation.one_to_one?.should be_false
    end
  end
end
