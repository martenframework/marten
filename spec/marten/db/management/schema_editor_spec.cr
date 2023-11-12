require "./spec_helper"

describe Marten::DB::Management::SchemaEditor do
  describe "::for" do
    it "returns the expected schema editor object for the passed connection" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      for_mysql do
        schema_editor.should be_a Marten::DB::Management::SchemaEditor::MySQL
      end

      for_postgresql do
        schema_editor.should be_a Marten::DB::Management::SchemaEditor::PostgreSQL
      end

      for_sqlite do
        schema_editor.should be_a Marten::DB::Management::SchemaEditor::SQLite
      end
    end
  end

  describe "::run_for" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "yields a schema editor instance and runs deferred statement once the block completes" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::Reference.new("foo", TestUser.db_table, "id"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      project_state.add_table(table_state)

      Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
        schema_editor.create_table(table_state)
      end

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              ["bigint", "bigint(20)"].includes?(column_type).should be_true
            end
          end

          db.query(
            "SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME " \
            "FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE " \
            "WHERE REFERENCED_TABLE_NAME = '#{TestUser.db_table}' AND REFERENCED_COLUMN_NAME = 'id'"
          ) do |rs|
            rs.each do
              table_name = rs.read(String)
              next unless table_name == "schema_editor_test_table"
              column_name = rs.read(String)
              column_name.should eq "foo"
            end
          end
        end

        for_postgresql do
          db.query(
            "SELECT column_name, data_type FROM information_schema.columns " \
            "WHERE table_name = 'schema_editor_test_table'"
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.should eq "bigint"
            end
          end

          db.query(
            <<-SQL
              SELECT
                kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
              FROM information_schema.table_constraints AS tc
              JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
              JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
              WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name='schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"

              to_table = rs.read(String)
              to_table.should eq TestUser.db_table

              to_column = rs.read(String)
              to_column.should eq "id"
            end
          end
        end

        for_sqlite do
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.downcase.should eq "integer"
            end
          end

          db.query("PRAGMA foreign_key_list(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              rs.read(Int32 | Int64)

              to_table = rs.read(String)
              to_table.should eq TestUser.db_table

              from_column = rs.read(String)
              from_column.should eq "foo"

              to_column = rs.read(String)
              to_column.should eq "id"
            end
          end
        end
      end
    end

    it "yields a schema editor instance and wraps the block in a transaction by default" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::String.new("foo", max_size: 155),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      expect_raises(Exception, "Unexpected") do
        Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
          schema_editor.create_table(table_state)
          raise "Unexpected error"
        end
      end

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      if schema_editor.ddl_rollbackable?
        introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
        introspector.table_names.includes?("schema_editor_test_table").should be_false
      end
    end

    it "allows to explicitly disable atomicity" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::String.new("foo", max_size: 155),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      expect_raises(Exception, "Unexpected") do
        Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default, atomic: false) do |schema_editor|
          schema_editor.create_table(table_state)
          raise "Unexpected error"
        end
      end

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      introspector.table_names.includes?("schema_editor_test_table").should be_true
    end
  end
end
