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

  describe "#optimize" do
    it "returns the expected result if the other operation is deleting the same table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )
      other_operation = Marten::DB::Migration::Operation::DeleteTable.new("test_table")

      result = operation.optimize(other_operation)

      result.completed?.should be_true
      result.operations.should be_empty
    end

    it "returns the expected result if the other operation is deleting another table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )
      other_operation = Marten::DB::Migration::Operation::DeleteTable.new("other_test_table")

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation is renaming the same table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [
          Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
        ],
        indexes: [
          Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
        ],
      )
      other_operation = Marten::DB::Migration::Operation::RenameTable.new("test_table", "renamed_table")

      result = operation.optimize(other_operation)

      result.completed?.should be_true
      result.operations.size.should eq 1
      op = result.operations.first.as(Marten::DB::Migration::Operation::CreateTable)
      op.name.should eq "renamed_table"
      op.columns.should eq operation.columns
      op.unique_constraints.should eq operation.unique_constraints
      op.indexes.should eq operation.indexes
    end

    it "returns the expected result if the other operation is renaming another table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )
      other_operation = Marten::DB::Migration::Operation::RenameTable.new("other_test_table", "renamed_table")

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end

    it "returns the expected result if the other operation is adding a column to the same table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [
          Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
        ],
        indexes: [
          Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
        ],
      )
      other_operation = Marten::DB::Migration::Operation::AddColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("xyz", null: false)
      )

      result = operation.optimize(other_operation)

      result.completed?.should be_true
      result.operations.size.should eq 1
      op = result.operations.first.as(Marten::DB::Migration::Operation::CreateTable)
      op.name.should eq operation.name
      op.columns.should eq(operation.columns + [other_operation.column])
      op.unique_constraints.should eq operation.unique_constraints
      op.indexes.should eq operation.indexes
    end

    it "returns the expected result if the other operation is adding a column to another table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )
      other_operation = Marten::DB::Migration::Operation::AddColumn.new(
        "other_test_table",
        Marten::DB::Management::Column::BigInt.new("xyz", null: false)
      )

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end

    it "returns the expected result if the other operation is changing a column of the same table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [
          Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
        ],
        indexes: [
          Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
        ],
      )
      other_operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      result = operation.optimize(other_operation)

      result.completed?.should be_true
      result.operations.size.should eq 1
      op = result.operations.first.as(Marten::DB::Migration::Operation::CreateTable)
      op.name.should eq operation.name
      op.columns.select { |c| c.name != "foo" }.should eq operation.columns.select { |c| c.name != "foo" }
      op.columns.select { |c| c.name == "foo" }.should eq [other_operation.column]
      op.unique_constraints.should eq operation.unique_constraints
      op.indexes.should eq operation.indexes
    end

    it "returns the expected result if the other operation is changing a column of another table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )
      other_operation = Marten::DB::Migration::Operation::ChangeColumn.new(
        "other_test_table",
        Marten::DB::Management::Column::BigInt.new("xyz", null: false)
      )

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end

    it "returns the expected result if the other operation references the considered table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )
      other_operation = Marten::DB::Migration::Operation::RenameColumn.new("test_table", "foo", "renamed")

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation does not reference the considered table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )
      other_operation = Marten::DB::Migration::Operation::RemoveIndex.new("other_table", "test_index")

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end
  end

  describe "#references_column?" do
    it "returns true if the specified table and column corresponds to one of the table's columns" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )

      operation.references_column?("test_table", "foo").should be_true
      operation.references_column?("test_table", "bar").should be_true
    end

    it "returns true if the specified table and column corresponds to one of the table's referenced columns" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
          Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
        ] of Marten::DB::Management::Column::Base
      )

      operation.references_column?("other_table", "id").should be_true
    end

    it "returns false if the specified table and column are not referenced" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
          Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
        ] of Marten::DB::Management::Column::Base
      )

      operation.references_column?("unknown", "unknown").should be_false
      operation.references_column?("other_table", "other_column").should be_false
    end
  end

  describe "#references_table?" do
    it "returns true if the specified table corresponds to the created table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )

      operation.references_table?("test_table").should be_true
    end

    it "returns true if the specified table corresponds to a table referenced through the created table" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
          Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
        ] of Marten::DB::Management::Column::Base
      )

      operation.references_table?("other_table").should be_true
    end

    it "returns false if the specified table is not referenced" do
      operation = Marten::DB::Migration::Operation::CreateTable.new(
        name: "test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
          Marten::DB::Management::Column::Reference.new("other_id", "other_table", "id"),
        ] of Marten::DB::Management::Column::Base
      )

      operation.references_table?("unknown").should be_false
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
