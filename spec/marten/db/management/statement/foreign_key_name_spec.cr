require "./spec_helper"

describe Marten::DB::Management::Statement::ForeignKeyName do
  describe "#column" do
    it "returns the column name" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.column.should eq "test_column"
    end
  end

  describe "#references_column?" do
    it "returns true if the statement references the passed column as a column" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.references_column?("test_table", "test_column").should be_true
    end

    it "returns true if the statement references the passed column as a targeted column" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.references_column?("test_to_table", "test_to_column").should be_true
    end

    it "returns fale if the statement does not reference the passed column" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )

      statement.references_column?("test_table", "test_to_column").should be_false
      statement.references_column?("test_table", "unknown").should be_false
      statement.references_column?("test_to_table", "unknown").should be_false
      statement.references_column?("unknown", "test_column").should be_false
      statement.references_column?("unknown", "test_to_column").should be_false
    end
  end

  describe "#references_table?" do
    it "returns true if the statement references the passed table as a table" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.references_table?("test_table").should be_true
    end

    it "returns true if the statement references the passed table as a targeted table" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.references_table?("test_to_table").should be_true
    end

    it "returns false if the statement does not reference the passed table" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.references_table?("unknown").should be_false
    end
  end

  describe "#rename_column" do
    it "renames a given column as expected" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )

      statement.rename_column("test_table", "test_column", "test_column_renamed")

      statement.column.should eq "test_column_renamed"
      statement.to_column.should eq "test_to_column"
    end

    it "renames a given column as expected" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )

      statement.rename_column("test_to_table", "test_to_column", "test_to_column_renamed")

      statement.column.should eq "test_column"
      statement.to_column.should eq "test_to_column_renamed"
    end

    it "does not rename anything if the passed column is not referenced" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )

      statement.rename_column("test_table", "test_to_column", "test_to_column_renamed")
      statement.rename_column("test_to_table", "test_column", "test_column_renamed")
      statement.rename_column("test_table", "unknown", "unknown_renamed")
      statement.rename_column("test_to_table", "unknown", "unknown_renamed")
      statement.rename_column("unknown", "unknown", "unknown_renamed")

      statement.column.should eq "test_column"
      statement.to_column.should eq "test_to_column"
    end
  end

  describe "#rename_table" do
    it "renames a given table as expected" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )

      statement.rename_table("test_table", "test_table_renamed")

      statement.table.should eq "test_table_renamed"
      statement.to_table.should eq "test_to_table"
    end

    it "renames a given targeted table as expected" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )

      statement.rename_table("test_to_table", "test_to_table_renamed")

      statement.table.should eq "test_table"
      statement.to_table.should eq "test_to_table_renamed"
    end

    it "does not rename anything if the passed table is not referenced" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )

      statement.rename_table("unknown", "unknown_renamed")

      statement.table.should eq "test_table"
      statement.to_table.should eq "test_to_table"
    end
  end

  describe "#table" do
    it "returns the table name" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.table.should eq "test_table"
    end
  end

  describe "#to_column" do
    it "returns the targeted column name" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.to_column.should eq "test_to_column"
    end
  end

  describe "#to_table" do
    it "returns the targeted table name" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.to_table.should eq "test_to_table"
    end
  end

  describe "#to_s" do
    it "returns the expected output" do
      statement = Marten::DB::Management::Statement::ForeignKeyName.new(
        ->(_x : String, _y : Array(String), _z : String) { "indexname" },
        "test_table",
        "test_column",
        "test_to_table",
        "test_to_column"
      )
      statement.to_s.should eq "indexname"
    end
  end
end
