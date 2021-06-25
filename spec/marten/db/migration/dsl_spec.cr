require "./spec_helper"

describe Marten::DB::Migration::DSL do
  describe "#add_column" do
    it "allows to initialize an AddColumn operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_add_column

      test.operations[0].should be_a Marten::DB::Migration::Operation::AddColumn

      operation = test.operations[0].as(Marten::DB::Migration::Operation::AddColumn)
      operation.table_name.should eq "test_table"
      operation.column.should be_a Marten::DB::Management::Column::String

      column = operation.column.as(Marten::DB::Management::Column::String)
      column.name.should eq "test_column"
      column.max_size.should eq 155
      column.null?.should be_true
    end
  end

  describe "#create_table" do
    it "allows to initialize a CreateTable operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_create_table

      test.operations[0].should be_a Marten::DB::Migration::Operation::CreateTable

      operation = test.operations[0].as(Marten::DB::Migration::Operation::CreateTable)
      operation.name.should eq "test_table"

      operation.columns.size.should eq 3
      operation.columns[0].name.should eq "id"
      operation.columns[1].name.should eq "foo"
      operation.columns[2].name.should eq "bar"

      operation.unique_constraints.size.should eq 1
      operation.unique_constraints[0].name.should eq "cname"
      operation.unique_constraints[0].column_names.should eq ["foo", "bar"]
    end
  end

  describe "#delete_table" do
    it "allows to initialize a DeleteTable operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_delete_table

      test.operations[0].should be_a Marten::DB::Migration::Operation::DeleteTable

      operation = test.operations[0].as(Marten::DB::Migration::Operation::DeleteTable)
      operation.name.should eq "test_table"
    end
  end

  describe "#execute" do
    it "allows to initialize an ExecuteSQL operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_execute

      test.operations[0].should be_a Marten::DB::Migration::Operation::ExecuteSQL

      operation = test.operations[0].as(Marten::DB::Migration::Operation::ExecuteSQL)
      operation.forward_sql.should eq "SELECT 1"
      operation.backward_sql.should eq "SELECT 2"
    end
  end

  describe "#remove_column" do
    it "allows to initialize a RemoveColumn operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_remove_column

      test.operations[0].should be_a Marten::DB::Migration::Operation::RemoveColumn

      operation = test.operations[0].as(Marten::DB::Migration::Operation::RemoveColumn)
      operation.table_name.should eq "test_table"
      operation.column_name.should eq "test_column"
    end
  end

  describe "#rename_column" do
    it "allows to initialize a RenameColumn operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_rename_column

      test.operations[0].should be_a Marten::DB::Migration::Operation::RenameColumn

      operation = test.operations[0].as(Marten::DB::Migration::Operation::RenameColumn)
      operation.table_name.should eq "test_table"
      operation.old_name.should eq "old_column"
      operation.new_name.should eq "new_column"
    end
  end

  describe "#rename_table" do
    it "allows to initialize a RenameTable operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_rename_table

      test.operations[0].should be_a Marten::DB::Migration::Operation::RenameTable

      operation = test.operations[0].as(Marten::DB::Migration::Operation::RenameTable)
      operation.old_name.should eq "old_table"
      operation.new_name.should eq "new_table"
    end
  end
end

module Marten::DB::Migration::DSLSpec
  class Test
    include Marten::DB::Migration::DSL

    getter operations = [] of Marten::DB::Migration::Operation::Base

    def run_add_column
      add_column :test_table, :test_column, :string, max_size: 155, null: true
    end

    def run_create_table
      create_table :test_table do
        column :id, :big_auto, primary_key: true
        column :foo, :int, null: true
        column :bar, :int, null: true

        unique_constraint :cname, [:foo, :bar]
      end
    end

    def run_delete_table
      delete_table :test_table
    end

    def run_execute
      execute(
        (
          <<-SQL
          SELECT 1
          SQL
        ),
        (
          <<-SQL
          SELECT 2
          SQL
        )
      )
    end

    def run_remove_column
      remove_column :test_table, :test_column
    end

    def run_rename_column
      rename_column :test_table, :old_column, :new_column
    end

    def run_rename_table
      rename_table :old_table, :new_table
    end
  end
end
