require "./spec_helper"

describe Marten::DB::Migration::Operation::RenameColumn do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("operation_test_table", "old_column", "new_column")
      operation.describe.should eq "Rename old_column on operation_test_table table to new_column"
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

    it "renames the column as expected" do
      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("new_column"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("old_column"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RenameColumn.new("operation_test_table", "old_column", "new_column")

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      columns_details = introspector.columns_details(to_table_state.name)
      columns_details.map(&.name).sort!.should eq ["id", "old_column"]
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

    it "renames the column as expected" do
      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("old_column"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("new_column"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RenameColumn.new("operation_test_table", "old_column", "new_column")

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      columns_details = introspector.columns_details(to_table_state.name)
      columns_details.map(&.name).sort!.should eq ["id", "new_column"]
    end
  end

  describe "#mutate_state_forward" do
    it "renames the column in the right table state" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("old_column"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      operation = Marten::DB::Migration::Operation::RenameColumn.new("operation_test_table", "old_column", "new_column")
      operation.mutate_state_forward("my_app", project_state)

      table_state.get_column("new_column").should be_a Marten::DB::Management::Column::Int
    end
  end

  describe "#optimize" do
    it "returns the expected result if the other operation references the old column name" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "foo", "foo_renamed")
      other_operation = Marten::DB::Migration::Operation::AddColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation references the new column name" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "foo", "foo_renamed")
      other_operation = Marten::DB::Migration::Operation::AddColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo_renamed", null: false)
      )

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation does not reference the renamed column" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "foo", "foo_renamed")
      other_operation = Marten::DB::Migration::Operation::AddColumn.new(
        "other_table",
        Marten::DB::Management::Column::BigInt.new("other_column", null: false)
      )

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end
  end

  describe "#references_column?" do
    it "returns true if the passed column and table corresponds to the old column name" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "foo", "foo_renamed")

      operation.references_column?("test_table", "foo").should be_true
    end

    it "returns true if the passed column and table corresponds to the new column name" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "foo", "foo_renamed")

      operation.references_column?("test_table", "foo_renamed").should be_true
    end

    it "returns true if the passed column and table corresponds to another column of the same table" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "foo", "foo_renamed")

      operation.references_column?("test_table", "other").should be_false
    end

    it "returns true otherwise" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "foo", "foo_renamed")

      operation.references_column?("other_table", "other_column").should be_true
    end
  end

  describe "#references_table?" do
    it "always returns true" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "foo", "foo_renamed")

      operation.references_table?("test_table").should be_true
      operation.references_table?("other_table").should be_true
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("operation_test_table", "old_column", "new_column")
      operation.serialize.strip.should eq %{rename_column :operation_test_table, :old_column, :new_column}
    end
  end
end
