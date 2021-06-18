require "./spec_helper"

describe Marten::DB::Management::Statement::Columns do
  describe "#columns" do
    it "returns the associated column names" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["foo", "bar"]
      )
      statement.columns.should eq ["foo", "bar"]
    end
  end

  describe "#table" do
    it "returns the associated table name" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["column_name"]
      )
      statement.table.should eq "table_name"
    end
  end

  describe "#references_column?" do
    it "returns true if the statement references the passed table and column" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["foo", "bar"]
      )
      statement.references_column?("table_name", "foo").should be_true
      statement.references_column?("table_name", "bar").should be_true
    end

    it "returns false if the statement does not reference the passed table and column" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["foo", "bar"]
      )
      statement.references_column?("table_name", "unknown").should be_false
      statement.references_column?("unknown", "bar").should be_false
    end
  end

  describe "#references_table?" do
    it "returns true if the statement references the passed table" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["foo", "bar"]
      )
      statement.references_table?("table_name").should be_true
    end

    it "returns false if the statement does not reference the passed table" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["foo", "bar"]
      )
      statement.references_table?("unknown").should be_false
    end
  end

  describe "#rename_column" do
    it "renames a given column as expected" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["foo", "bar"]
      )

      statement.rename_column("table_name", "foo", "foo_renamed")

      statement.columns.should eq ["foo_renamed", "bar"]
    end

    it "does not rename anything if the passed column is not referenced" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["foo", "bar"]
      )

      statement.rename_column("table_name", "unknown", "foo_renamed")
      statement.rename_column("unknown", "foo", "foo_renamed")

      statement.columns.should eq ["foo", "bar"]
    end
  end

  describe "#rename_table" do
    it "renames a given table as expected" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["foo", "bar"]
      )

      statement.rename_table("table_name", "table_name_renamed")

      statement.table.should eq "table_name_renamed"
    end

    it "does not rename anything if the passed table is not referenced" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { x },
        "table_name",
        ["foo", "bar"]
      )

      statement.rename_table("unknown", "table_name_renamed")

      statement.table.should eq "table_name"
    end
  end

  describe "#to_s" do
    it "returns the expected output" do
      statement = Marten::DB::Management::Statement::Columns.new(
        ->(x : String) { "'#{x}'" },
        "table_name",
        ["foo", "bar"]
      )
      statement.to_s.should eq "'foo', 'bar'"
    end
  end
end
