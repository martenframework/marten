require "./spec_helper"

describe Marten::DB::Management::Migrations::Diff::Dependency::CreatedTable do
  describe "#app_label" do
    it "returns the app label on to which there is a dependency" do
      dependency = Marten::DB::Management::Migrations::Diff::Dependency::CreatedTable.new("app_label", "table_name")
      dependency.app_label.should eq "app_label"
    end
  end

  describe "#table_name" do
    it "returns the name of the table whose creation is required" do
      dependency = Marten::DB::Management::Migrations::Diff::Dependency::CreatedTable.new("app_label", "table_name")
      dependency.table_name.should eq "table_name"
    end
  end

  describe "#dependent?" do
    it "returns true if the operation creates the specified table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::CreatedTable.new("test_app", "test_table")

      dependency.dependent?(operation).should be_true
    end

    it "returns false if the operation creates another table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "other_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::CreatedTable.new("test_app", "test_table")

      dependency.dependent?(operation).should be_false
    end

    it "returns false for other operations" do
      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "my_table",
        Marten::DB::Management::Column::Int.new("my_column")
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::CreatedTable.new("test_app", "test_table")

      dependency.dependent?(operation).should be_false
    end
  end
end
