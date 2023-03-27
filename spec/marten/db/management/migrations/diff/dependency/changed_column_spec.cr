require "./spec_helper"

describe Marten::DB::Management::Migrations::Diff::Dependency::ChangedColumn do
  describe "#app_label" do
    it "returns the app label on to which there is a dependency" do
      dependency = Marten::DB::Management::Migrations::Diff::Dependency::ChangedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )
      dependency.app_label.should eq "app_label"
    end
  end

  describe "#column_name" do
    it "returns the name of the possibly changed column" do
      dependency = Marten::DB::Management::Migrations::Diff::Dependency::ChangedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )
      dependency.column_name.should eq "column_name"
    end
  end

  describe "#table_name" do
    it "returns the name of the table associated with the changed column" do
      dependency = Marten::DB::Management::Migrations::Diff::Dependency::ChangedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )
      dependency.table_name.should eq "table_name"
    end
  end

  describe "#dependent?" do
    it "returns true if the operation changes the specified column" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "table_name",
        Marten::DB::Management::Column::Int.new("column_name", null: true)
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::ChangedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )

      dependency.dependent?(operation).should be_true
    end

    it "returns false if the operation changes another column in the same table" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "table_name",
        Marten::DB::Management::Column::Int.new("other_column", null: true)
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::ChangedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )

      dependency.dependent?(operation).should be_false
    end

    it "returns false if the operation changes a column with the same name in another table" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "other_table_name",
        Marten::DB::Management::Column::Int.new("column_name", null: true)
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::ChangedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )

      dependency.dependent?(operation).should be_false
    end

    it "returns false if the operation changes another column in another table" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "other_table_name",
        Marten::DB::Management::Column::Int.new("other_column", null: true)
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::ChangedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )

      dependency.dependent?(operation).should be_false
    end

    it "returns false for other operations" do
      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "my_table",
        Marten::DB::Management::Column::Int.new("my_column")
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::ChangedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )

      dependency.dependent?(operation).should be_false
    end
  end
end
