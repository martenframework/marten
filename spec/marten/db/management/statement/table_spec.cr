require "./spec_helper"

describe Marten::DB::Management::Statement::Table do
  describe "#references_table?" do
    it "returns true if the statement references the passed table" do
      statement = Marten::DB::Management::Statement::Table.new(
        ->(x : String) { x },
        "table_name"
      )
      statement.references_table?("table_name").should be_true
    end

    it "returns false if the statement does not reference the passed table" do
      statement = Marten::DB::Management::Statement::Table.new(
        ->(x : String) { x },
        "table_name"
      )
      statement.references_table?("unknown").should be_false
    end
  end

  describe "#rename_table" do
    it "renames a given table as expected" do
      statement = Marten::DB::Management::Statement::Table.new(
        ->(x : String) { x },
        "table_name"
      )

      statement.rename_table("table_name", "table_name_renamed")

      statement.name.should eq "table_name_renamed"
    end

    it "does not rename anything if the passed table is not referenced" do
      statement = Marten::DB::Management::Statement::Table.new(
        ->(x : String) { x },
        "table_name"
      )

      statement.rename_table("unknown", "table_name_renamed")

      statement.name.should eq "table_name"
    end
  end

  describe "#table" do
    it "returns the associated table name" do
      statement = Marten::DB::Management::Statement::Table.new(
        ->(x : String) { x },
        "table_name"
      )
      statement.name.should eq "table_name"
    end
  end

  describe "#to_s" do
    it "returns the expected output" do
      statement = Marten::DB::Management::Statement::Table.new(
        ->(x : String) { "'#{x}'" },
        "table_name"
      )
      statement.to_s.should eq "'table_name'"
    end
  end
end
