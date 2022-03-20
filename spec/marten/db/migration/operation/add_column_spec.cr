require "./spec_helper"

describe Marten::DB::Migration::Operation::AddColumn do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "my_table",
        Marten::DB::Management::Column::Int.new("my_column")
      )
      operation.describe.should eq "Add my_column to my_table table"
    end
  end

  describe "#mutate_db_backward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
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

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(to_table_state)

      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "operation_test_table",
        Marten::DB::Management::Column::Int.new("foo", default: 42)
      )

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Connection.default.introspector
      columns_details = introspector.columns_details(to_table_state.name)
      columns_details.map(&.name).sort!.should eq ["id"]
    end

    it "contributes the column to the project" do
      new_column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id"
      )

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      from_project_state.add_table(from_table_state)

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          new_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      to_project_state.add_table(to_table_state)

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(to_table_state)

      operation = Marten::DB::Migration::Operation::AddColumn.new("operation_test_table", new_column)

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Connection.default.introspector
      columns_details = introspector.columns_details(to_table_state.name)
      columns_details.map(&.name).sort!.should eq ["id"]
    end
  end

  describe "#mutate_db_forward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
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

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "operation_test_table",
        Marten::DB::Management::Column::Int.new("foo", default: 42)
      )

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Connection.default.introspector
      db_column = introspector.columns_details(to_table_state.name).find { |c| c.name == "foo" }.not_nil!

      for_mysql { db_column.type.should eq "int" }
      for_postgresql { db_column.type.should eq "integer" }
      for_sqlite { db_column.type.downcase.should eq "integer" }
    end

    it "contributes the column to the project" do
      new_column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id"
      )

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      from_project_state.add_table(from_table_state)

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          new_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      to_project_state.add_table(to_table_state)

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::AddColumn.new("operation_test_table", new_column)

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Connection.default.introspector
      columns_details = introspector.columns_details(to_table_state.name)
      columns_details.map(&.name).sort!.should eq ["id", "test"]
    end
  end

  describe "#mutate_state_forward" do
    it "mutates a project state as expected" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "operation_test_table",
        Marten::DB::Management::Column::Int.new("foo", default: 42)
      )

      operation.mutate_state_forward("my_app", project_state)

      table_state.get_column("foo").should eq column
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::AddColumn.new(
        "my_table",
        Marten::DB::Management::Column::Int.new("my_column", default: 42)
      )
      operation.serialize.strip.should eq %{add_column :my_table, :my_column, :int, default: 42}
    end
  end
end
