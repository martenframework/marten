require "./spec_helper"

describe Marten::DB::Migration::Operation::ExecuteSQL do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::ExecuteSQL.new("SELECT 1")
      operation.describe.should eq "Run raw SQL"
    end
  end

  describe "#mutate_db_backward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.delete_table("operation_test_table")
      end
    end

    it "executes the backward SQL if one is defined" do
      operation = Marten::DB::Migration::Operation::ExecuteSQL.new(
        "SELECT 1",
        "CREATE TABLE operation_test_table (test varchar(255))"
      )

      schema_editor = Marten::DB::Connection.default.schema_editor

      operation.mutate_db_backward(
        "my_app",
        schema_editor,
        Marten::DB::Management::ProjectState.new,
        Marten::DB::Management::ProjectState.new
      )

      Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table").should be_true
    end

    it "does nothing if no backward SQL is defined" do
      operation = Marten::DB::Migration::Operation::ExecuteSQL.new("SELECT 1")

      schema_editor = Marten::DB::Connection.default.schema_editor

      operation.mutate_db_backward(
        "my_app",
        schema_editor,
        Marten::DB::Management::ProjectState.new,
        Marten::DB::Management::ProjectState.new
      ).should be_nil
    end
  end

  describe "#mutate_db_forward" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table")
        schema_editor.delete_table("operation_test_table")
      end
    end

    it "executes the backward SQL if one is defined" do
      operation = Marten::DB::Migration::Operation::ExecuteSQL.new(
        "CREATE TABLE operation_test_table (test varchar(255))"
      )

      schema_editor = Marten::DB::Connection.default.schema_editor

      operation.mutate_db_forward(
        "my_app",
        schema_editor,
        Marten::DB::Management::ProjectState.new,
        Marten::DB::Management::ProjectState.new
      )

      Marten::DB::Connection.default.introspector.table_names.includes?("operation_test_table").should be_true
    end
  end

  describe "#mutate_state_forward" do
    it "does nothing" do
      operation = Marten::DB::Migration::Operation::ExecuteSQL.new("SELECT 1")

      project_state = Marten::DB::Management::ProjectState.new

      operation.mutate_state_forward("my_app", project_state)

      project_state.tables.should be_empty
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation when only a forward SQL script is defined" do
      operation = Marten::DB::Migration::Operation::ExecuteSQL.new("SELECT 1")
      operation.serialize.strip.should eq(
        (
          <<-OPERATION
          execute <<-SQL
            SELECT 1
          SQL
          OPERATION
        ).strip
      )
    end
  end

  it "returns the expected serialized version of the operation when forward and backward SQL scripts are defined" do
    operation = Marten::DB::Migration::Operation::ExecuteSQL.new("SELECT 1", "SELECT 2")
    operation.serialize.strip.should eq(
      (
        <<-OPERATION
        execute(
          (
            <<-SQL
              SELECT 1
            SQL
          ),
          (
            <<-SQL
              SELECT 2
            SQL
          )
        )
        OPERATION
      ).strip
    )
  end
end
