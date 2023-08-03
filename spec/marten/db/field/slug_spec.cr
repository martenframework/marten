require "./spec_helper"

describe Marten::DB::Field::Slug do
  describe "#max_size" do
    it "returns 50 by default" do
      field = Marten::DB::Field::Slug.new("my_field")
      field.max_size.should eq 50
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::Slug.new("my-slug", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::String
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_true
      column.max_size.should eq 50
      column.default.should be_nil
    end
  end

  describe "#validate" do
    it "does not add an error to the record if the string contains a valid slug" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug")
      field.validate(obj, "th1s-1s-val1d-slug")

      obj.errors.size.should eq 0
    end

    it "adds an error to the record if the string contains two consecutive dashes" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug")
      field.validate(obj, "th1s-1s-not--val1d-slug")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "my-slug"
      obj.errors.first.message.should eq "Enter a valid slug."
    end

    it "adds an error to the record if the string starts with a non alphanumeric character" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug", null: false)
      field.validate(obj, "-foo")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "my-slug"
      obj.errors.first.message.should eq "Enter a valid slug."
    end

    it "adds an error to the record if the string ends with a non alphanumeric character" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug", null: false)
      field.validate(obj, "foo-")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "my-slug"
      obj.errors.first.message.should eq "Enter a valid slug."
    end

    it "adds an error to the record if the string contains non-ascii characters" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug", null: false)
      field.validate(obj, "foo-✓-bar")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "my-slug"
      obj.errors.first.message.should eq "Enter a valid slug."
    end
  end
end
