require "./spec_helper"

describe Marten::DB::Management::Migrations::Diff do
  describe "#detect" do
    it "is able to detect the addition of a new table" do
      from_project_state = Marten::DB::Management::ProjectState.new

      new_table_state = Marten::DB::Management::TableState.new(
        app_label: "app",
        name: "new_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [
          Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
        ]
      )
      to_project_state = Marten::DB::Management::ProjectState.new(tables: [new_table_state])

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].name.ends_with?("create_new_table_table").should be_true

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::CreateTable

      operation = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::CreateTable)
      operation.name.should eq "new_table"

      operation.columns.size.should eq 3
      operation.columns[0].should be_a Marten::DB::Management::Column::BigInt
      operation.columns[0].name.should eq "id"
      operation.columns[0].as(Marten::DB::Management::Column::BigInt).primary_key?.should be_true
      operation.columns[0].as(Marten::DB::Management::Column::BigInt).auto?.should be_true
      operation.columns[1].should be_a Marten::DB::Management::Column::BigInt
      operation.columns[1].name.should eq "foo"
      operation.columns[2].should be_a Marten::DB::Management::Column::BigInt
      operation.columns[2].name.should eq "bar"

      operation.unique_constraints.size.should eq 1
      operation.unique_constraints[0].name.should eq "test_constraint"
      operation.unique_constraints[0].column_names.should eq ["foo", "bar"]
    end

    it "is able to detect the addition of new columns to existing tables" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("newcol"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].name.ends_with?("add_newcol_to_test_table_table").should be_true

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::AddColumn

      operation = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::AddColumn)
      operation.table_name.should eq "test_table"
      operation.column.should be_a Marten::DB::Management::Column::BigInt
      operation.column.name.should eq "newcol"
    end

    it "is able to detect the removal of a column from an existing tables" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("oldcol"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].name.ends_with?("remove_oldcol_on_test_table_table").should be_true

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::RemoveColumn

      operation = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RemoveColumn)
      operation.table_name.should eq "test_table"
      operation.column_name.should eq "oldcol"
    end

    it "is able to detect a renamed table" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "old_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "new_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].name.ends_with?("rename_old_table_table_to_new_table").should be_true

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::RenameTable

      operation = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RenameTable)
      operation.old_name.should eq "old_table"
      operation.new_name.should eq "new_table"
    end

    it "is able to detect the addition of new unique constraints to existing tables" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].name.ends_with?("add_test_constraint_unique_constraint_to_test_table_table").should be_true

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::AddUniqueConstraint

      operation = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::AddUniqueConstraint)
      operation.table_name.should eq "test_table"
      operation.unique_constraint.name.should eq "test_constraint"
      operation.unique_constraint.column_names.should eq ["foo", "bar"]
    end

    it "is able to detect the removal unique constraints from existing tables" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].name.ends_with?("remove_test_constraint_unique_constraint_from_test_table_table").should be_true

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::RemoveUniqueConstraint

      operation = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RemoveUniqueConstraint)
      operation.table_name.should eq "test_table"
      operation.unique_constraint_name.should eq "test_constraint"
    end

    it "generates one addition operation and one removal operation when a unique constraint is changed" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("renamed_test_constraint", ["foo", "bar"]),
            ] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].operations.size.should eq 2

      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::RemoveUniqueConstraint
      operation_1 = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RemoveUniqueConstraint)
      operation_1.table_name.should eq "test_table"
      operation_1.unique_constraint_name.should eq "test_constraint"

      changes["app"][0].operations[1].should be_a Marten::DB::Migration::Operation::AddUniqueConstraint
      operation_2 = changes["app"][0].operations[1].as(Marten::DB::Migration::Operation::AddUniqueConstraint)
      operation_2.table_name.should eq "test_table"
      operation_2.unique_constraint.name.should eq "renamed_test_constraint"
      operation_2.unique_constraint.column_names.should eq ["foo", "bar"]
    end

    it "generates the expected operation for unique constraints added to a renamed table" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "renamed_test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].operations.size.should eq 2

      operation_1 = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RenameTable)
      operation_1.old_name.should eq "test_table"
      operation_1.new_name.should eq "renamed_test_table"

      changes["app"][0].operations[1].should be_a Marten::DB::Migration::Operation::AddUniqueConstraint
      operation_2 = changes["app"][0].operations[1].as(Marten::DB::Migration::Operation::AddUniqueConstraint)
      operation_2.table_name.should eq "renamed_test_table"
      operation_2.unique_constraint.name.should eq "test_constraint"
      operation_2.unique_constraint.column_names.should eq ["foo", "bar"]
    end

    it "generates the expected operation for unique constraints removed from a renamed table" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "renamed_test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].operations.size.should eq 2

      operation_1 = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RenameTable)
      operation_1.old_name.should eq "test_table"
      operation_1.new_name.should eq "renamed_test_table"

      changes["app"][0].operations[1].should be_a Marten::DB::Migration::Operation::RemoveUniqueConstraint
      operation_2 = changes["app"][0].operations[1].as(Marten::DB::Migration::Operation::RemoveUniqueConstraint)
      operation_2.table_name.should eq "renamed_test_table"
      operation_2.unique_constraint_name.should eq "test_constraint"
    end

    it "is able to detect the addition of new index to existing tables" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            indexes: [
              Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
            ]
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].name.ends_with?("add_test_index_index_to_test_table_table").should be_true

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::AddIndex

      operation = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::AddIndex)
      operation.table_name.should eq "test_table"
      operation.index.name.should eq "test_index"
      operation.index.column_names.should eq ["foo", "bar"]
    end

    it "is able to detect the removal indexes from existing tables" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            indexes: [
              Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
            ]
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].name.ends_with?("remove_test_index_index_from_test_table_table").should be_true

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::RemoveIndex

      operation = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RemoveIndex)
      operation.table_name.should eq "test_table"
      operation.index_name.should eq "test_index"
    end

    it "generates one addition operation and one removal operation when an index is changed" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            indexes: [
              Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
            ]
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            indexes: [
              Marten::DB::Management::Index.new("renamed_test_index", ["foo", "bar"]),
            ]
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].operations.size.should eq 2

      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::RemoveIndex
      operation_1 = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RemoveIndex)
      operation_1.table_name.should eq "test_table"
      operation_1.index_name.should eq "test_index"

      changes["app"][0].operations[1].should be_a Marten::DB::Migration::Operation::AddIndex
      operation_2 = changes["app"][0].operations[1].as(Marten::DB::Migration::Operation::AddIndex)
      operation_2.table_name.should eq "test_table"
      operation_2.index.name.should eq "renamed_test_index"
      operation_2.index.column_names.should eq ["foo", "bar"]
    end

    it "generates the expected operation for indexes added to a renamed table" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "renamed_test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            indexes: [
              Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
            ]
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].operations.size.should eq 2

      operation_1 = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RenameTable)
      operation_1.old_name.should eq "test_table"
      operation_1.new_name.should eq "renamed_test_table"

      changes["app"][0].operations[1].should be_a Marten::DB::Migration::Operation::AddIndex
      operation_2 = changes["app"][0].operations[1].as(Marten::DB::Migration::Operation::AddIndex)
      operation_2.table_name.should eq "renamed_test_table"
      operation_2.index.name.should eq "test_index"
      operation_2.index.column_names.should eq ["foo", "bar"]
    end

    it "generates the expected operation for indexes removed from a renamed table" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            indexes: [
              Marten::DB::Management::Index.new("test_index", ["foo", "bar"]),
            ]
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "renamed_test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("foo"),
              Marten::DB::Management::Column::BigInt.new("bar"),
            ] of Marten::DB::Management::Column::Base
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["app"].size.should eq 1

      changes["app"][0].operations.size.should eq 2

      operation_1 = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RenameTable)
      operation_1.old_name.should eq "test_table"
      operation_1.new_name.should eq "renamed_test_table"

      changes["app"][0].operations[1].should be_a Marten::DB::Migration::Operation::RemoveIndex
      operation_2 = changes["app"][0].operations[1].as(Marten::DB::Migration::Operation::RemoveIndex)
      operation_2.table_name.should eq "renamed_test_table"
      operation_2.index_name.should eq "test_index"
    end

    it "is able to detect renamed columns" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("col", null: false, default: 42),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::BigInt.new("renamed_col", null: false, default: 42),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes["app"][0].name.ends_with?("rename_col_on_test_table_table_to_renamed_col").should be_true

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::RenameColumn

      operation = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::RenameColumn)
      operation.table_name.should eq "test_table"
      operation.old_name.should eq "col"
      operation.new_name.should eq "renamed_col"
    end

    it "properly generates a dependency between an added table containing a foreign key and the target table" do
      from_project_state = Marten::DB::Management::ProjectState.new

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::ForeignKey.new("other_id", "other_table", "id"),
            ] of Marten::DB::Management::Column::Base
          ),
          Marten::DB::Management::TableState.new(
            app_label: "other_app",
            name: "other_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            ] of Marten::DB::Management::Column::Base
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 2
      changes["app"].size.should eq 1
      changes["other_app"].size.should eq 1

      changes["other_app"][0].operations.size.should eq 1
      changes["other_app"][0].dependencies.should be_empty
      changes["other_app"][0].operations[0].should be_a Marten::DB::Migration::Operation::CreateTable
      operation_1 = changes["other_app"][0].operations[0].as(Marten::DB::Migration::Operation::CreateTable)
      operation_1.name.should eq "other_table"

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::CreateTable
      changes["app"][0].dependencies.size.should eq 1
      changes["app"][0].dependencies[0].should eq({"other_app", "__first__"})
      operation_2 = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::CreateTable)
      operation_2.name.should eq "test_table"
    end

    it "properly generates a dependency between an added foreign key and the target table" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            ] of Marten::DB::Management::Column::Base
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::ForeignKey.new("other_id", "other_table", "id"),
            ] of Marten::DB::Management::Column::Base
          ),
          Marten::DB::Management::TableState.new(
            app_label: "other_app",
            name: "other_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            ] of Marten::DB::Management::Column::Base
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 2
      changes["app"].size.should eq 1
      changes["other_app"].size.should eq 1

      changes["other_app"][0].operations.size.should eq 1
      changes["other_app"][0].dependencies.should be_empty
      changes["other_app"][0].operations[0].should be_a Marten::DB::Migration::Operation::CreateTable
      operation_1 = changes["other_app"][0].operations[0].as(Marten::DB::Migration::Operation::CreateTable)
      operation_1.name.should eq "other_table"

      changes["app"][0].operations.size.should eq 1
      changes["app"][0].dependencies.size.should eq 1
      changes["app"][0].dependencies[0].should eq({"other_app", "__first__"})
      changes["app"][0].operations[0].should be_a Marten::DB::Migration::Operation::AddColumn
      operation_2 = changes["app"][0].operations[0].as(Marten::DB::Migration::Operation::AddColumn)
      operation_2.table_name.should eq "test_table"
      operation_2.column.name.should eq "other_id"
    end
  end
end
