require "./spec_helper"

describe Marten::DB::Management::Constraint::Unique do
  describe "::new" do
    it "allows to initialize a unique constraint from name and column names strings" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new(
        "new_constraint",
        column_names: ["author_id", "title"]
      )
      unique_constraint.name.should eq "new_constraint"
      unique_constraint.column_names.should eq ["author_id", "title"]
    end

    it "allows to initialize a unique constraint from name and column names symbols" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new(
        :new_constraint,
        column_names: [:author_id, :title]
      )
      unique_constraint.name.should eq "new_constraint"
      unique_constraint.column_names.should eq ["author_id", "title"]
    end
  end

  describe "#==" do
    it "returns true if the other object is the same object" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new(
        :new_constraint,
        column_names: [:author_id, :title]
      )
      other_unique_constraint = unique_constraint

      other_unique_constraint.should eq unique_constraint
    end

    it "returns true if the other objects corresponds to the same unique constraint configuration" do
      Marten::DB::Management::Constraint::Unique.new(
        :new_constraint,
        column_names: [:author_id, :title]
      ).should eq(
        Marten::DB::Management::Constraint::Unique.new(
          :new_constraint,
          column_names: [:author_id, :title]
        )
      )
    end

    it "returns false if the other unique constraint has a different name" do
      Marten::DB::Management::Constraint::Unique.new(
        :new_constraint,
        column_names: [:author_id, :title]
      ).should_not eq(
        Marten::DB::Management::Constraint::Unique.new(
          :other_constraint,
          column_names: [:author_id, :title]
        )
      )
    end

    it "returns false if the other unique constraint has not the same columns names" do
      Marten::DB::Management::Constraint::Unique.new(
        :new_constraint,
        column_names: [:author_id, :title]
      ).should_not eq(
        Marten::DB::Management::Constraint::Unique.new(
          :new_constraint,
          column_names: [:author_id]
        )
      )
    end
  end

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

  describe "#clone" do
    it "clones the considered unique constraint" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new(
        "new_constraint",
        column_names: ["author_id", "title"]
      )
      cloned_unique_constraint = unique_constraint.clone

      cloned_unique_constraint.should_not be unique_constraint
      cloned_unique_constraint.name.should eq unique_constraint.name
      cloned_unique_constraint.column_names.should eq unique_constraint.column_names
      cloned_unique_constraint.column_names.should_not be unique_constraint.column_names
    end
  end

  describe "#serialize_args" do
    it "returns a serialized version of the unique constraint arguments" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new(
        "new_constraint",
        column_names: ["author_id", "title"]
      )
      unique_constraint.serialize_args.should eq %{"new_constraint", ["author_id", "title"]}
    end
  end
end
