require "./spec_helper"

describe Marten::DB::Management::Constraint::Unique do
  describe "#name" do
    it "returns the unique constraint name" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new(
        "new_constraint",
        column_names: ["author_id", "title"]
      )
      unique_constraint.name.should eq "new_constraint"
    end
  end

  describe "#column_names" do
    it "returns the unique constraint column names" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new(
        "new_constraint",
        column_names: ["author_id", "title"]
      )
      unique_constraint.column_names.should eq ["author_id", "title"]
    end
  end
end
