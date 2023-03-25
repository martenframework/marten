require "./spec_helper"

describe Marten::DB::Migration::Operation::RemoveColumn do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "test_column")
      operation.describe.should eq "Remove test_column on operation_test_table table"
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

    it "adds the column to the table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "foo")

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      db_column = introspector.columns_details(to_table_state.name).find! { |c| c.name == "foo" }

      for_mysql { db_column.type.should eq "int" }
      for_postgresql { db_column.type.should eq "integer" }
      for_sqlite { db_column.type.downcase.should eq "integer" }
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

    it "removes the column from the table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "foo")

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      columns_details = introspector.columns_details(to_table_state.name)
      columns_details.map(&.name).sort!.should eq ["id"]
    end
  end

  describe "#mutate_state_forward" do
    it "mutates a project state as expected" do
      column_to_remove = Marten::DB::Management::Column::Int.new("foo", default: 42)
      other_column = Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [other_column, column_to_remove] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "foo")

      operation.mutate_state_forward("my_app", project_state)

      table_state.columns.should eq [other_column] of Marten::DB::Management::Column::Base
    end
  end

  describe "#optimize" do
    it "returns the expected result if the other operation is deleting the same table" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("test_table", "foo")
      other_operation = Marten::DB::Migration::Operation::DeleteTable.new("test_table")

      result = operation.optimize(other_operation)

      result.completed?.should be_true
      result.operations.should eq [other_operation]
    end

    it "returns the expected result if the other operation is deleting another table" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("test_table", "foo")
      other_operation = Marten::DB::Migration::Operation::DeleteTable.new("other_test_table")

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expectedd result if the other operation references the same column" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("test_table", "foo")
      other_operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expectedd result if the other operation does not reference the same column" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("test_table", "foo")
      other_operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "other_table",
        Marten::DB::Management::Column::BigInt.new("other_column", null: false)
      )

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end
  end

  describe "#references_column?" do
    it "always returns true" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("test_table", "foo")

      operation.references_column?("test_table", "test_column").should be_true
    end
  end

  describe "#references_table?" do
    it "always returns true" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("test_table", "foo")

      operation.references_table?("test_table").should be_true
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::RemoveColumn.new("operation_test_table", "foo")
      operation.serialize.strip.should eq %{remove_column :operation_test_table, :foo}
    end
  end
end
