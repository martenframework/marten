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
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("operation_test_table")))
      end
    end

    it "creates the table" do
      columns = [
        Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
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

      schema_editor = Marten::DB::Connection.default.schema_editor

      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table")

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table").should be_true
    end
  end

  describe "#mutate_db_forward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("operation_test_table")))
      end
    end

    it "deletes the table" do
      columns = [
        Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
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

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table")

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table").should be_false
    end
  end

  describe "#mutate_state_forward" do
    it "mutates a project state as expected" do
      columns = [
        Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
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

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::DeleteTable.new(name: "operation_test_table")
      operation.serialize.strip.should eq "delete_table :operation_test_table"
    end
  end
end
