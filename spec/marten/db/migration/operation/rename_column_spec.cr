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
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.execute(schema_editor.delete_table_statement("operation_test_table"))
      end
    end

    it "renames the column as expected" do
      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::Int.new("new_column"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::Int.new("old_column"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RenameColumn.new("operation_test_table", "old_column", "new_column")

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      column_names = [] of String

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM operation_test_table") do |rs|
            rs.each do
              column_names << rs.read(String)
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_names << rs.read(String)
            end
          end
        {% else %}
          db.query("PRAGMA table_info(operation_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_names << rs.read(String)
            end
          end
        {% end %}
      end

      column_names.to_set.should eq ["id", "old_column"].to_set
    end
  end

  describe "#mutate_db_forward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.execute(schema_editor.delete_table_statement("operation_test_table"))
      end
    end

    it "renames the column as expected" do
      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::Int.new("old_column"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::Int.new("new_column"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::RenameColumn.new("operation_test_table", "old_column", "new_column")

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      column_names = [] of String

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM operation_test_table") do |rs|
            rs.each do
              column_names << rs.read(String)
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_names << rs.read(String)
            end
          end
        {% else %}
          db.query("PRAGMA table_info(operation_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_names << rs.read(String)
            end
          end
        {% end %}
      end

      column_names.to_set.should eq ["id", "new_column"].to_set
    end
  end

  describe "#mutate_state_forward" do
    it "renames the column in the right table state" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
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

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::RenameColumn.new("operation_test_table", "old_column", "new_column")
      operation.serialize.strip.should eq %{rename_column :operation_test_table, :old_column, :new_column}
    end
  end
end
