require "./spec_helper"

describe Marten::DB::Management::Statement::IndexName do
  describe "#columns" do
    it "returns the column names" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )
      statement.columns.should eq ["foo", "bar"]
    end
  end

  describe "#references_column?" do
    it "returns true if the statement references the passed table and column" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )
      statement.references_column?("test_table", "foo").should be_true
      statement.references_column?("test_table", "bar").should be_true
    end

    it "returns false if the statement does not reference the passed table and column" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )
      statement.references_column?("test_table", "unknown").should be_false
      statement.references_column?("unknown", "bar").should be_false
    end
  end

  describe "#references_table?" do
    it "returns true if the statement references the passed table" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )
      statement.references_table?("test_table").should be_true
    end

    it "returns false if the statement does not reference the passed table" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )
      statement.references_table?("unknown").should be_false
    end
  end

  describe "#rename_column" do
    it "renames a given column as expected" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )

      statement.rename_column("test_table", "foo", "foo_renamed")

      statement.columns.should eq ["foo_renamed", "bar"]
    end

    it "does not rename anything if the passed column is not referenced" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )

      statement.rename_column("test_table", "unknown", "foo_renamed")
      statement.rename_column("unknown", "foo", "foo_renamed")

      statement.columns.should eq ["foo", "bar"]
    end
  end

  describe "#rename_table" do
    it "renames a given table as expected" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )

      statement.rename_table("test_table", "test_table_renamed")

      statement.table.should eq "test_table_renamed"
    end

    it "does not rename anything if the passed table is not referenced" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )

      statement.rename_table("unknown", "test_table_renamed")

      statement.table.should eq "test_table"
    end
  end

  describe "#suffix" do
    it "returns the index suffix" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )
      statement.suffix.should eq "suffix"
    end
  end

  describe "#table" do
    it "returns the table name" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )
      statement.table.should eq "test_table"
    end
  end

  describe "#to_s" do
    it "returns the expected output" do
      statement = Marten::DB::Management::Statement::IndexName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        ["foo", "bar"],
        "suffix"
      )
      statement.to_s.should eq "indexname"
    end
  end
end
