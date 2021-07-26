require "./spec_helper"

describe Marten::DB::Migration::Operation::RenameTable do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::RenameTable.new("old_table", "new_table")
      operation.describe.should eq "Rename old_table table to new_table"
    end
  end

  describe "#mutate_db_backward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.delete_table("operation_test_table")
      end

      if Marten::DB::Connection.default.introspector.table_names.includes?("renamed_operation_test_table")
        schema_editor.delete_table("renamed_operation_test_table")
      end
    end

    it "renames the column as expected" do
      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "renamed_operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RenameTable.new(
        "operation_test_table",
        "renamed_operation_test_table"
      )

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table").should be_true
      Marten::DB::Connection.default.introspector.table_names.includes?("renamed_operation_test_table").should be_false
    end
  end

  describe "#mutate_db_forward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.delete_table("operation_test_table")
      end

      if Marten::DB::Connection.default.introspector.table_names.includes?("renamed_operation_test_table")
        schema_editor.delete_table("renamed_operation_test_table")
      end
    end

    it "renames the column as expected" do
      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "renamed_operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RenameTable.new(
        "operation_test_table",
        "renamed_operation_test_table"
      )

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table").should be_false
      Marten::DB::Connection.default.introspector.table_names.includes?("renamed_operation_test_table").should be_true
    end
  end

  describe "#mutate_state_forward" do
    it "renames the table in the project state as expected" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      operation = Marten::DB::Migration::Operation::RenameTable.new(
        "operation_test_table",
        "renamed_operation_test_table"
      )

      operation.mutate_state_forward("my_app", project_state)

      table_state.name.should eq "renamed_operation_test_table"
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::RenameTable.new("old_table", "new_table")
      operation.serialize.strip.should eq %{rename_table :old_table, :new_table}
    end
  end
end
