require "./spec_helper"

describe Marten::DB::Field::URL do
  describe "#max_size" do
    it "returns 200 by default" do
      field = Marten::DB::Field::URL.new("my_field")
      field.max_size.should eq 200
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::URL.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::String
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.max_size.should eq 200
      column.default.should be_nil
    end
  end

  describe "#validate" do
    it "adds an error to the record if the string size is greater than the allowed limit" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::URL.new("url", null: false)
      field.validate(obj, "a" * 201)

      obj.errors.first.field.should eq "url"
      obj.errors.first.message.should eq "The maximum allowed length is 200"
    end

    it "adds an error to the record if the string does not correspond to a valid URL" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::URL.new("url", null: false)
      field.validate(obj, "this is not a URL")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "url"
      obj.errors.first.message.should eq "Enter a valid URL."
    end

    it "does not add an error to the record if the string contains a valid URL" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::URL.new("url", null: false)
      field.validate(obj, "https://example.com/foo/bar")

      obj.errors.size.should eq 0
    end

    it "does not add an invalid URL error if the field value is empty" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::URL.new("url", null: false, blank: false)
      field.validate(obj, "")

      obj.errors.size.should eq 0
    end
  end
end
