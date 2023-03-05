require "./spec_helper"

describe Marten::DB::Migration::Operation::CreateTable do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [
          Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
        ]
      )
      operation.describe.should eq "Create operation_test_table table"
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

      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "operation_test_table",
        columns: columns,
        unique_constraints: unique_constraints
      )

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      introspector.table_names.includes?("operation_test_table").should be_false
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

    it "creates the new table" do
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

      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "operation_test_table",
        columns: columns,
        unique_constraints: unique_constraints
      )

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      introspector.table_names.includes?("operation_test_table").should be_true
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

      project_state = Marten::DB::Management::ProjectState.new

      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "operation_test_table",
        columns: columns,
        unique_constraints: unique_constraints
      )

      operation.mutate_state_forward("my_app", project_state)

      table_state = project_state.get_table("my_app", "operation_test_table")
      table_state.app_label.should eq "my_app"
      table_state.name.should eq "operation_test_table"
      table_state.columns.should eq columns
      table_state.unique_constraints.should eq unique_constraints
    end

    it "properly configure custom indexes into the generated table state" do
      columns = [
        Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        Marten::DB::Management::Column::Int.new("foo"),
        Marten::DB::Management::Column::Int.new("bar"),
      ] of Marten::DB::Management::Column::Base
      indexes = [
        Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
      ]

      project_state = Marten::DB::Management::ProjectState.new

      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "operation_test_table",
        columns: columns,
        indexes: indexes
      )

      operation.mutate_state_forward("my_app", project_state)

      table_state = project_state.get_table("my_app", "operation_test_table")
      table_state.app_label.should eq "my_app"
      table_state.name.should eq "operation_test_table"
      table_state.columns.should eq columns
      table_state.indexes.should eq indexes
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [
          Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
        ]
      )
      operation.serialize.strip.should eq(
        (
          <<-OPERATION
          create_table :operation_test_table do
            column :id, :big_int, primary_key: true, auto: true
            column :foo, :int
            column :bar, :int

            unique_constraint :test_constraint, [:foo, :bar]
          end
          OPERATION
        ).strip
      )
    end

    it "properly includes indexes when the operation contains custom indexes" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        indexes: [
          Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
        ]
      )
      operation.serialize.strip.should eq(
        (
          <<-OPERATION
          create_table :operation_test_table do
            column :id, :big_int, primary_key: true, auto: true
            column :foo, :int
            column :bar, :int

            index :test_index, [:foo, :bar]
          end
          OPERATION
        ).strip
      )
    end
  end
end
