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
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("operation_test_table")
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

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::ChangeColumn.new("operation_test_table", new_column)

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      db_column = introspector.columns_details(from_table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy
      db_column = db_column.not_nil!

      for_mysql { db_column.type.should eq "int" }
      for_postgresql { db_column.type.should eq "integer" }
      for_sqlite { db_column.type.downcase.should eq "integer" }

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

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::ChangeColumn.new("operation_test_table", new_column)

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      introspector.foreign_key_constraint_names(from_table_state.name, "test").should be_empty
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

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::ChangeColumn.new("operation_test_table", new_column)

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      db_column = introspector.columns_details(from_table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy
      db_column = db_column.not_nil!

      for_mysql { db_column.type.should eq "bigint" }
      for_postgresql { db_column.type.should eq "bigint" }
      for_sqlite { db_column.type.downcase.should eq "integer" }

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

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::ChangeColumn.new("operation_test_table", new_column)

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
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

  describe "#optimize" do
    it "returns the expected result if the other operation is removing the considered column" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::Int.new("my_column", null: true)
      )
      other_operation = Marten::DB::Migration::Operation::RemoveColumn.new("test_table", "my_column")

      result = operation.optimize(other_operation)

      result.completed?.should be_true
      result.operations.should eq [other_operation]
    end

    it "returns the expected result if the other operation is removing another column in the same table" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::Int.new("my_column", null: true)
      )
      other_operation = Marten::DB::Migration::Operation::RemoveColumn.new("test_table", "other_column")

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation is removing another column in another table" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::Int.new("my_column", null: true)
      )
      other_operation = Marten::DB::Migration::Operation::RemoveColumn.new("other_table", "other_column")

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation references the considered column" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::Int.new("my_column", null: true)
      )
      other_operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "my_column", "new_name")

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation does not reference the considered column" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::Int.new("my_column", null: true)
      )
      other_operation = Marten::DB::Migration::Operation::RemoveIndex.new("other_table", "test_index")

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end
  end

  describe "#references_column?" do
    it "returns true if the specified table and column correspond to the operation table and column" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      operation.references_column?("test_table", "foo").should be_true
    end

    it "returns true if the specified table and column are targeted by the column via a reference" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
      )

      operation.references_column?("other_table", "id").should be_true
    end

    it "returns false if the specified table and column are not referenced" do
      operation_1 = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      operation_1.references_column?("test_table", "bar").should be_false
      operation_1.references_column?("other_table", "other_column").should be_false

      operation_2 = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
      )

      operation_2.references_column?("test_table", "bar").should be_false
      operation_2.references_column?("other_table", "bar").should be_false
      operation_2.references_column?("unknown", "bar").should be_false
    end
  end

  describe "#references_table?" do
    it "returns true if the specified table corresponds to the operation table" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      operation.references_table?("test_table").should be_true
    end

    it "returns true if the specified table corresponds to the reference column's target table" do
      operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
      )

      operation.references_table?("other_table").should be_true
    end

    it "returns false if the specified table is not referenced" do
      operation_1 = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      operation_1.references_table?("other_table").should be_false

      operation_2 = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
      )

      operation_2.references_table?("unknown").should be_false
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
