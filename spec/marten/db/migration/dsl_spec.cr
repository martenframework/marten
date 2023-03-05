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

  describe "#add_unique_constraint" do
    it "allows to initialize an AddIndex operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_add_index

      test.operations[0].should be_a Marten::DB::Migration::Operation::AddIndex

      operation = test.operations[0].as(Marten::DB::Migration::Operation::AddIndex)
      operation.table_name.should eq "test_table"
      operation.index.should be_a Marten::DB::Management::Index

      operation.index.name.should eq "test_index"
      operation.index.column_names.should eq ["foo", "bar"]
    end
  end

  describe "#add_unique_constraint" do
    it "allows to initialize an AddUniqueConstraint operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_add_unique_constraint

      test.operations[0].should be_a Marten::DB::Migration::Operation::AddUniqueConstraint

      operation = test.operations[0].as(Marten::DB::Migration::Operation::AddUniqueConstraint)
      operation.table_name.should eq "test_table"
      operation.unique_constraint.should be_a Marten::DB::Management::Constraint::Unique

      operation.unique_constraint.name.should eq "test_constraint"
      operation.unique_constraint.column_names.should eq ["foo", "bar"]
    end
  end

  describe "#change_column" do
    it "allows to initialize a ChangeColumn operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_change_column

      test.operations[0].should be_a Marten::DB::Migration::Operation::ChangeColumn

      operation = test.operations[0].as(Marten::DB::Migration::Operation::ChangeColumn)
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

  describe "#faked" do
    it "allows to register faked operations" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_faked

      test.faked_operations_registered.should be_true

      test.operations[0].should be_a Marten::DB::Migration::Operation::DeleteTable

      operation = test.operations[0].as(Marten::DB::Migration::Operation::DeleteTable)
      operation.name.should eq "test_table"
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

  describe "#remove_index" do
    it "allows to initialize a RemoveIndex operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_remove_index

      test.operations[0].should be_a Marten::DB::Migration::Operation::RemoveIndex

      operation = test.operations[0].as(Marten::DB::Migration::Operation::RemoveIndex)
      operation.table_name.should eq "test_table"
      operation.index_name.should eq "test_index"
    end
  end

  describe "#remove_unique_constraint" do
    it "allows to initialize a RemoveUniqueConstraint operation" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_remove_unique_constraint

      test.operations[0].should be_a Marten::DB::Migration::Operation::RemoveUniqueConstraint

      operation = test.operations[0].as(Marten::DB::Migration::Operation::RemoveUniqueConstraint)
      operation.table_name.should eq "test_table"
      operation.unique_constraint_name.should eq "test_constraint"
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

  describe "#run_code" do
    it "allows to initialize a RunCode operation with a forward proc and a backward proc" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_run_code_with_forward_and_backward_code

      test.operations[0].should be_a Marten::DB::Migration::Operation::RunCode

      operation = test.operations[0].as(Marten::DB::Migration::Operation::RunCode)

      from_project_state = Marten::DB::Management::ProjectState.new([] of Marten::DB::Management::TableState)
      to_project_state = Marten::DB::Management::ProjectState.new([] of Marten::DB::Management::TableState)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      test.run_code_direction.should be_nil

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)
      test.run_code_direction.should eq "forward"

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)
      test.run_code_direction.should eq "backward"
    end

    it "allows to initialize a RunCode operation with a forward proc only" do
      test = Marten::DB::Migration::DSLSpec::Test.new
      test.run_run_code_with_forward_code_only

      test.operations[0].should be_a Marten::DB::Migration::Operation::RunCode

      operation = test.operations[0].as(Marten::DB::Migration::Operation::RunCode)

      from_project_state = Marten::DB::Management::ProjectState.new([] of Marten::DB::Management::TableState)
      to_project_state = Marten::DB::Management::ProjectState.new([] of Marten::DB::Management::TableState)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      test.run_code_direction.should be_nil

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)
      test.run_code_direction.should eq "forward"

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)
      test.run_code_direction.should eq "forward"
    end
  end
end

module Marten::DB::Migration::DSLSpec
  class Test
    include Marten::DB::Migration::DSL

    @faked_operations_registered = false

    getter faked_operations_registered
    getter operations = [] of Marten::DB::Migration::Operation::Base
    getter run_code_direction : String? = nil

    setter run_code_direction

    def run_add_column
      add_column :test_table, :test_column, :string, max_size: 155, null: true
    end

    def run_add_index
      add_index :test_table, :test_index, [:foo, :bar]
    end

    def run_add_unique_constraint
      add_unique_constraint :test_table, :test_constraint, [:foo, :bar]
    end

    def run_change_column
      change_column :test_table, :test_column, :string, max_size: 155, null: true
    end

    def run_create_table
      create_table :test_table do
        column :id, :big_int, primary_key: true, auto: true
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

    def run_faked
      faked do
        delete_table :test_table
      end
    end

    def run_remove_column
      remove_column :test_table, :test_column
    end

    def run_remove_index
      remove_index :test_table, :test_index
    end

    def run_remove_unique_constraint
      remove_unique_constraint :test_table, :test_constraint
    end

    def run_rename_column
      rename_column :test_table, :old_column, :new_column
    end

    def run_rename_table
      rename_table :old_table, :new_table
    end

    def run_run_code_with_forward_and_backward_code
      run_code :run_forward_code, :run_backward_code
    end

    def run_run_code_with_forward_code_only
      run_code :run_forward_code
    end

    def run_forward_code
      self.run_code_direction = "forward"
    end

    def run_backward_code
      self.run_code_direction = "backward"
    end

    private def register_operation(operation)
      operations << operation
    end

    private def with_faked_operations_registration(&)
      @faked_operations_registered = true
      yield
    end
  end
end
