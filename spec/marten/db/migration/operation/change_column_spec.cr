require "./spec_helper"

describe Marten::DB::Migration::Operation::ChangeColumn do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "my_table",
        Marten::DB::Management::Column::Int.new("my_column", null: true)
      )
      operation.describe.should eq "Change my_column on my_table table"
    end
  end

  describe "#mutate_db_backward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.delete_table("operation_test_table")
      end
    end

    it "changes the column backward" do
      old_column = Marten::DB::Management::Column::Int.new("foo", null: true)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", null: false)

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          new_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::ChangeColumn.new("operation_test_table", new_column)

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Connection.default.introspector

      db_column = introspector.columns_details(from_table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy
      db_column = db_column.not_nil!

      for_mysql { db_column.type.should eq "int" }
      for_postgresql { db_column.type.should eq "integer" }
      for_sqlite { db_column.type.should eq "integer" }

      db_column.nullable?.should be_true
    end

    it "contributes the column to the project" do
      old_column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id",
        foreign_key: true
      )
      new_column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id",
        foreign_key: false
      )

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
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

      operation = Marten::DB::Migration::Operation::ChangeColumn.new("operation_test_table", new_column)

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Connection.default.introspector
      introspector.foreign_key_constraint_names(from_table_state.name, "test").should be_empty
    end
  end

  describe "#mutate_db_forward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.delete_table("operation_test_table")
      end
    end

    it "changes the column forward" do
      old_column = Marten::DB::Management::Column::Int.new("foo", null: true)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", null: false)

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          new_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::ChangeColumn.new("operation_test_table", new_column)

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Connection.default.introspector

      db_column = introspector.columns_details(from_table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy
      db_column = db_column.not_nil!

      for_mysql { db_column.type.should eq "bigint" }
      for_postgresql { db_column.type.should eq "bigint" }
      for_sqlite { db_column.type.should eq "integer" }

      db_column.nullable?.should be_false
    end

    it "contributes the column to the project" do
      old_column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id",
        foreign_key: true
      )
      new_column = Marten::DB::Management::Column::Reference.new(
        "test",
        to_table: TestUser.db_table,
        to_column: "id",
        foreign_key: false
      )

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
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

      operation = Marten::DB::Migration::Operation::ChangeColumn.new("operation_test_table", new_column)

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Connection.default.introspector
      introspector.foreign_key_constraint_names(from_table_state.name, "test").should be_empty
    end
  end

  describe "#mutate_state_forward" do
    it "mutates a project state as expected" do
      old_column = Marten::DB::Management::Column::Int.new("foo", null: true)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", null: false)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      operation = Marten::DB::Migration::Operation::ChangeColumn.new("operation_test_table", new_column)

      operation.mutate_state_forward("my_app", project_state)

      table_state.get_column("foo").should eq new_column
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "my_table",
        Marten::DB::Management::Column::Int.new("my_column", null: true)
      )
      operation.serialize.strip.should eq "change_column :my_table, :my_column, :int, null: true"
    end
  end
end
