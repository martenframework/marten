require "./spec_helper"

describe Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn do
  describe "#app_label" do
    it "returns the app label on to which there is a dependency" do
      dependency = Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )
      dependency.app_label.should eq "app_label"
    end
  end

  describe "#column_name" do
    it "returns the name of the possibly added column" do
      dependency = Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )
      dependency.column_name.should eq "column_name"
    end
  end

  describe "#dependent?" do
    it "returns true if the operation creates a table with the table name and column name" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "table_name",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("column_name"),
          Marten::DB::Management::Column::Int.new("bar"),
          Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
        ] of Marten::DB::Management::Column::Base
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )

      dependency.dependent?(operation).should be_true
    end

    it "returns false if the operation creates a table with the table name but not the column name" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "table_name",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
          Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
        ] of Marten::DB::Management::Column::Base
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )

      dependency.dependent?(operation).should be_false
    end

    it "returns false if the operation creates another table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "other_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
          Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
        ] of Marten::DB::Management::Column::Base
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )

      dependency.dependent?(operation).should be_false
    end

    it "returns true if the operation adds the expected column to the expected table" do
      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "table_name",
        Marten::DB::Management::Column::BigInt.new("column_name", null: false)
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )

      dependency.dependent?(operation).should be_true
    end

    it "returns false if the operation adds the another column to the expected table" do
      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "table_name",
        Marten::DB::Management::Column::BigInt.new("column_name", null: false)
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "foo"
      )

      dependency.dependent?(operation).should be_false
    end

    it "returns false if the operation adds the another column to another table" do
      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "table_name",
        Marten::DB::Management::Column::BigInt.new("column_name", null: false)
      )

      dependency = Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn.new(
        "app_label",
        table_name: "other_table",
        column_name: "foo"
      )

      dependency.dependent?(operation).should be_false
    end
  end

  describe "#table_name" do
    it "returns the name of the table associated with the added column" do
      dependency = Marten::DB::Management::Migrations::Diff::Dependency::AddedColumn.new(
        "app_label",
        table_name: "table_name",
        column_name: "column_name"
      )
      dependency.table_name.should eq "table_name"
    end
  end
end
