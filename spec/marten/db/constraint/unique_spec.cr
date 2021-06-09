require "./spec_helper"

describe Marten::DB::Constraint::Unique do
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

  describe "#to_management_constraint" do
    it "returns the management version of the constraint" do
      unique_constraint = Marten::DB::Constraint::Unique.new(
        "new_constraint",
        fields: [Post.get_field("author"), Post.get_field("title")]
      )
      management_constraint = unique_constraint.to_management_constraint
      management_constraint.name.should eq "new_constraint"
      management_constraint.column_names.should eq ["author_id", "title"]
    end

    it "raises if a field does not have an associated database column" do
      unique_constraint = Marten::DB::Constraint::Unique.new(
        "new_constraint",
        fields: [TestUser.get_field("tags"), TestUser.get_field("email")]
      )
      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Field 'tags' cannot be used as part of a unique constraint because it is not associated with a database column"
      ) do
        unique_constraint.to_management_constraint
      end
    end
  end
end
