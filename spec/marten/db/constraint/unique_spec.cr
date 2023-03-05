require "./spec_helper"

describe Marten::DB::Constraint::Unique do
  describe "#clone" do
    it "clones the unique constraint" do
      unique_constraint = Marten::DB::Constraint::Unique.new(
        "new_constraint",
        fields: [Post.get_field("author"), Post.get_field("title")]
      )
      cloned_unique_constraint = unique_constraint.clone

      cloned_unique_constraint.should_not be unique_constraint
      cloned_unique_constraint.name.should eq unique_constraint.name
      cloned_unique_constraint.fields.should eq unique_constraint.fields
    end
  end

  describe "#name" do
    it "returns the unique constraint name" do
      unique_constraint = Marten::DB::Constraint::Unique.new(
        "new_constraint",
        fields: [Post.get_field("author"), Post.get_field("title")]
      )
      unique_constraint.name.should eq "new_constraint"
    end
  end

  describe "#fields" do
    it "returns the unique constraint fields" do
      unique_constraint = Marten::DB::Constraint::Unique.new(
        "new_constraint",
        fields: [Post.get_field("author"), Post.get_field("title")]
      )
      unique_constraint.fields.should eq [Post.get_field("author"), Post.get_field("title")]
    end
  end
end
