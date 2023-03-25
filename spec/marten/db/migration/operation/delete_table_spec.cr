require "./spec_helper"

describe Marten::DB::Migration::Operation::DeleteTable do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table")
      operation.describe.should eq "Delete operation_test_table table"
    end
  end

  describe "#mutate_db_backward" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("operation_test_table")
        schema_editor.delete_table("operation_test_table")
      end
    end

    it "creates the table" do
      columns = [
        Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        Marten::DB::Management::Column::Int.new("foo"),
        Marten::DB::Management::Column::Int.new("bar"),
      ] of Marten::DB::Management::Column::Base
      unique_constraints = [
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
      ]

      from_project_state = Marten::DB::Management::ProjectState.new

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns,
        unique_constraints,
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table")

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      introspector.table_names.includes?("operation_test_table").should be_true
    end
  end

  describe "#mutate_db_forward" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("operation_test_table")
        schema_editor.delete_table("operation_test_table")
      end
    end

    it "deletes the table" do
      columns = [
        Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        Marten::DB::Management::Column::Int.new("foo"),
        Marten::DB::Management::Column::Int.new("bar"),
      ] of Marten::DB::Management::Column::Base
      unique_constraints = [
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
      ]

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns,
        unique_constraints,
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_project_state = Marten::DB::Management::ProjectState.new

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table")

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      introspector.table_names.includes?("operation_test_table").should be_false
    end
  end

  describe "#mutate_state_forward" do
    it "mutates a project state as expected" do
      columns = [
        Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        Marten::DB::Management::Column::Int.new("foo"),
        Marten::DB::Management::Column::Int.new("bar"),
      ] of Marten::DB::Management::Column::Base
      unique_constraints = [
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
      ]
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns,
        unique_constraints,
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table")

      operation.mutate_state_forward("my_app", project_state)

      project_state.tables.should be_empty
    end
  end

  describe "#optimize" do
    it "returns the expected result if the other operation references the table" do
      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "test_table")
      other_operation = Marten::DB::Migration::Operation::AddColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation does not reference the table" do
      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "test_table")
      other_operation = Marten::DB::Migration::Operation::AddColumn.new(
        "other_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end
  end

  describe "#references_column?" do
    it "always return true" do
      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "test_table")

      operation.references_column?("test_table", "foo").should be_true
      operation.references_column?("unknown", "unknown").should be_true
    end
  end

  describe "#references_table?" do
    it "always return true" do
      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "test_table")

      operation.references_table?("test_table").should be_true
      operation.references_table?("unknown").should be_true
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table")
      operation.serialize.strip.should eq "delete_table :operation_test_table"
    end
  end
end
