require "./spec_helper"

describe Marten::DB::Management::Migrations::Diff do
  describe "#detect" do
    it "is able to detect the addition of a new table" do
      from_project_state = Marten::DB::Management::ProjectState.new

      new_table_state = Marten::DB::Management::TableState.new(
        app_label: "my_app",
        name: "new_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
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
      changes["my_app"].size.should eq 1

      changes["my_app"][0].name.ends_with?("create_new_table_table").should be_true

      changes["my_app"][0].operations.size.should eq 1
      changes["my_app"][0].operations[0].should be_a Marten::DB::Migration::Operation::CreateTable

      operation = changes["my_app"][0].operations[0].as(Marten::DB::Migration::Operation::CreateTable)
      operation.name.should eq "new_table"

      operation.columns.size.should eq 3
      operation.columns[0].should be_a Marten::DB::Management::Column::BigAuto
      operation.columns[0].name.should eq "id"
      operation.columns[0].as(Marten::DB::Management::Column::BigAuto).primary_key?.should be_true
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
            app_label: "my_app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "my_app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
              Marten::DB::Management::Column::BigInt.new("newcol"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["my_app"].size.should eq 1

      changes["my_app"][0].name.ends_with?("add_newcol_to_test_table_table").should be_true

      changes["my_app"][0].operations.size.should eq 1
      changes["my_app"][0].operations[0].should be_a Marten::DB::Migration::Operation::AddColumn

      operation = changes["my_app"][0].operations[0].as(Marten::DB::Migration::Operation::AddColumn)
      operation.table_name.should eq "test_table"
      operation.column.should be_a Marten::DB::Management::Column::BigInt
      operation.column.name.should eq "newcol"
    end

    it "is able to detect the removal of a column from an existing tables" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "my_app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
              Marten::DB::Management::Column::BigInt.new("oldcol"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "my_app",
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["my_app"].size.should eq 1

      changes["my_app"][0].name.ends_with?("remove_oldcol_on_test_table_table").should be_true

      changes["my_app"][0].operations.size.should eq 1
      changes["my_app"][0].operations[0].should be_a Marten::DB::Migration::Operation::RemoveColumn

      operation = changes["my_app"][0].operations[0].as(Marten::DB::Migration::Operation::RemoveColumn)
      operation.table_name.should eq "test_table"
      operation.column_name.should eq "oldcol"
    end

    it "is able to detect a renamed table" do
      from_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "my_app",
            name: "old_table",
            columns: [
              Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      to_project_state = Marten::DB::Management::ProjectState.new(
        tables: [
          Marten::DB::Management::TableState.new(
            app_label: "my_app",
            name: "new_table",
            columns: [
              Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ]
      )

      diff = Marten::DB::Management::Migrations::Diff.new(from_project_state, to_project_state)
      changes = diff.detect

      changes.size.should eq 1
      changes["my_app"].size.should eq 1

      changes["my_app"][0].name.ends_with?("rename_old_table_table_to_new_table").should be_true

      changes["my_app"][0].operations.size.should eq 1
      changes["my_app"][0].operations[0].should be_a Marten::DB::Migration::Operation::RenameTable

      operation = changes["my_app"][0].operations[0].as(Marten::DB::Migration::Operation::RenameTable)
      operation.old_name.should eq "old_table"
      operation.new_name.should eq "new_table"
    end
  end
end
