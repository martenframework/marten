require "./spec_helper"

describe Marten::DB::Management::Introspector::ColumnInfo do
  describe "#name" do
    it "returns the column name" do
      column_details = Marten::DB::Management::Introspector::ColumnInfo.new(
        name: "test_col",
        type: "integer",
        nullable: true,
        default: nil
      )
      column_details.name.should eq "test_col"
    end
  end

  describe "#type" do
    it "returns the column type" do
      column_details = Marten::DB::Management::Introspector::ColumnInfo.new(
        name: "test_col",
        type: "integer",
        nullable: true,
        default: nil
      )
      column_details.type.should eq "integer"
    end
  end

  describe "#nullable?" do
    it "returns true if the column is nullable" do
      column_details = Marten::DB::Management::Introspector::ColumnInfo.new(
        name: "test_col",
        type: "integer",
        nullable: true,
        default: nil
      )
      column_details.nullable?.should be_true
    end

    it "returns false if the column is nullable" do
      column_details = Marten::DB::Management::Introspector::ColumnInfo.new(
        name: "test_col",
        type: "integer",
        nullable: false,
        default: nil
      )
      column_details.nullable?.should be_false
    end
  end

  describe "#default" do
    it "returns the default value" do
      column_details = Marten::DB::Management::Introspector::ColumnInfo.new(
        name: "test_col",
        type: "integer",
        nullable: false,
        default: "hello"
      )
      column_details.default.should eq "hello"
    end
  end

  describe "#character_maximum_length" do
    it "returns nil by default" do
      column_details = Marten::DB::Management::Introspector::ColumnInfo.new(
        name: "test_col",
        type: "integer",
        nullable: false,
        default: "hello"
      )
      column_details.character_maximum_length.should be_nil
    end

    it "returns the maximum character length if applicable" do
      column_details = Marten::DB::Management::Introspector::ColumnInfo.new(
        name: "test_col",
        type: "integer",
        nullable: false,
        default: "hello",
        character_maximum_length: 255
      )
      column_details.character_maximum_length.should eq 255
    end
  end
end
