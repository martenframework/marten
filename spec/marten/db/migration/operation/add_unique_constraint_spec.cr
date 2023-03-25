require "./spec_helper"

describe Marten::DB::Migration::Operation::AddUniqueConstraint do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "test_table",
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])
      )
      operation.describe.should eq "Add test_constraint unique constraint to test_table table"
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

    it "removes the unique constraint from the table" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [unique_constraint]
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "operation_test_table",
        unique_constraint
      )

      operation.mutate_db_backward("my_app", schema_editor, from_project_state, to_project_state)

      constraint_names = [] of String

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query(
            <<-SQL
              SELECT
                CONSTRAINT_NAME,
                CONSTRAINT_TYPE
              FROM information_schema.TABLE_CONSTRAINTS
              WHERE TABLE_NAME = 'operation_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_names << rs.read(String)
            end
          end
        end

        for_postgresql do
          db.query(
            <<-SQL
              SELECT con.conname, con.contype
              FROM pg_catalog.pg_constraint con
              INNER JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid
              INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace
              WHERE rel.relname = 'operation_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_names << rs.read(String)
            end
          end
        end

        for_sqlite do
          db.query(
            <<-SQL
              SELECT
                il.name AS constraint_name,
                ii.name AS column_name
              FROM
                sqlite_master AS m,
                pragma_index_list(m.name) AS il,
                pragma_index_info(il.name) AS ii
              WHERE
                m.type = 'table' AND
                il.origin = 'u' AND
                m.tbl_name = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              constraint_names << rs.read(String)
            end
          end
        end
      end

      constraint_names.includes?("test_constraint").should be_false
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

    it "adds the unique constraint to the table" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [unique_constraint]
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(from_table_state)

      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "operation_test_table",
        unique_constraint
      )

      operation.mutate_db_forward("my_app", schema_editor, from_project_state, to_project_state)

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query(
            <<-SQL
              SELECT
                CONSTRAINT_NAME,
                CONSTRAINT_TYPE
              FROM information_schema.TABLE_CONSTRAINTS
              WHERE TABLE_NAME = 'operation_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              next unless constraint_name == "test_constraint"
              constraint_type = rs.read(String)
              constraint_type.should eq "UNIQUE"
            end
          end

          constraint_columns = [] of String

          db.query(
            <<-SQL
              SELECT COLUMN_NAME, CONSTRAINT_NAME
              FROM information_schema.KEY_COLUMN_USAGE
              WHERE TABLE_NAME = 'operation_test_table';
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              constraint_name = rs.read(String)
              next unless constraint_name == "test_constraint"
              constraint_columns << column_name
            end
          end

          constraint_columns.to_set.should eq ["foo", "bar"].to_set
        end

        for_postgresql do
          db.query(
            <<-SQL
              SELECT con.conname, con.contype
              FROM pg_catalog.pg_constraint con
              INNER JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid
              INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace
              WHERE rel.relname = 'operation_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              next unless constraint_name == "test_constraint"
              constraint_type = rs.read(Char)
              constraint_type.should eq 'u'
            end
          end

          constraint_columns = [] of String

          db.query(
            <<-SQL
              SELECT
                pgc.conname AS constraint_name,
                ccu.column_name
              FROM pg_constraint pgc
              JOIN pg_namespace nsp ON nsp.oid = pgc.connamespace
              JOIN pg_class cls ON pgc.conrelid = cls.oid
              LEFT JOIN information_schema.constraint_column_usage ccu ON pgc.conname = ccu.constraint_name
                AND nsp.nspname = ccu.constraint_schema
              WHERE contype = 'u' AND ccu.table_name = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              column_name = rs.read(String)
              next unless constraint_name == "test_constraint"
              constraint_columns << column_name
            end
          end

          constraint_columns.to_set.should eq ["foo", "bar"].to_set
        end

        for_sqlite do
          db.query("PRAGMA index_list(operation_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              rs.read(String)
              unique = rs.read(Int32 | Int64)
              unique.should eq 1
            end
          end

          constraint_columns = [] of String

          db.query(
            <<-SQL
              SELECT
                il.name AS constraint_name,
                ii.name AS column_name
              FROM
                sqlite_master AS m,
                pragma_index_list(m.name) AS il,
                pragma_index_info(il.name) AS ii
              WHERE
                m.type = 'table' AND
                il.origin = 'u' AND
                m.tbl_name = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              rs.read(String)
              column_name = rs.read(String)
              constraint_columns << column_name
            end
          end

          constraint_columns.to_set.should eq ["foo", "bar"].to_set
        end
      end
    end
  end

  describe "#mutate_state_forward" do
    it "mutates a project state as expected" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "operation_test_table",
        unique_constraint
      )

      operation.mutate_state_forward("my_app", project_state)

      table_state.get_unique_constraint("test_constraint").should eq unique_constraint
    end
  end

  describe "#optimize" do
    it "returns the expected result if the other operation references the unique constraint table" do
      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "test_table",
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])
      )
      other_operation = Marten::DB::Migration::Operation::RenameTable.new("test_table", "renamed_table")

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation does not reference the unique constraint table" do
      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "test_table",
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])
      )
      other_operation = Marten::DB::Migration::Operation::RenameTable.new("other_test_table", "renamed_table")

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end
  end

  describe "#references_column?" do
    it "returns true if the specified column is referenced" do
      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "test_table",
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])
      )

      operation.references_column?("test_table", "foo").should be_true
      operation.references_column?("test_table", "bar").should be_true
    end

    it "returns false if the specified column is not referenced" do
      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "test_table",
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])
      )

      operation.references_column?("test_table", "xyz").should be_false
      operation.references_column?("unknown", "xyz").should be_false
    end
  end

  describe "#references_table?" do
    it "returns true if the specified table is referenced" do
      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "test_table",
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])
      )

      operation.references_table?("test_table").should be_true
    end

    it "returns false if the specified table is not referenced" do
      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "test_table",
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])
      )

      operation.references_table?("other_test_table").should be_false
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::AddUniqueConstraint.new(
        "my_table",
        Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])
      )
      operation.serialize.strip.should eq %{add_unique_constraint :my_table, :test_constraint, [:foo, :bar]}
    end
  end
end
