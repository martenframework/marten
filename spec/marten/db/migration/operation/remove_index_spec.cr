require "./spec_helper"

describe Marten::DB::Migration::Operation::RemoveIndex do
  describe "#describe" do
    it "returns the expected description" do
      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "operation_test_table",
        "test_index"
      )
      operation.describe.should eq "Remove test_index index from operation_test_table table"
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

    it "adds the index to the table" do
      index = Marten::DB::Management::Index.new("test_index", ["foo", "bar"])

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base
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
        indexes: [index]
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
        schema_editor.create_table(from_table_state)
      end

      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "operation_test_table",
        "test_index"
      )

      operation.mutate_db_backward(
        "my_app",
        Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default),
        from_project_state,
        to_project_state
      )

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          index_name = nil
          index_columns = [] of String

          db.query(
            <<-SQL
              SHOW INDEX FROM operation_test_table;
            SQL
          ) do |rs|
            rs.each do
              rs.read(String) # table
              rs.read(Bool)   # non_unique

              current_index_name = rs.read(String)
              next unless current_index_name == "test_index"

              index_name = current_index_name

              rs.read(Int32 | Int64) # seq_in_index

              index_columns << rs.read(String)
            end
          end

          index_name.should eq "test_index"
          index_columns.to_set.should eq ["foo", "bar"].to_set
        end

        for_postgresql do
          index_name = nil
          index_columns = [] of String

          db.query(
            <<-SQL
              SELECT
                i.relname AS index_name,
                a.attname AS column_name
              FROM
                pg_class t,
                pg_class i,
                pg_index ix,
                pg_attribute a
              WHERE
                t.oid = ix.indrelid
                AND i.oid = ix.indexrelid
                AND a.attrelid = t.oid
                AND a.attnum = ANY(ix.indkey)
                AND t.relkind = 'r'
                AND t.relname = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              current_index_name = rs.read(String)
              next unless current_index_name == "test_index"

              index_name = current_index_name
              index_columns << rs.read(String)
            end
          end

          index_name.should eq "test_index"
          index_columns.to_set.should eq ["foo", "bar"].to_set
        end

        for_sqlite do
          index_name = nil

          db.query("PRAGMA index_list(operation_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              current_index_name = rs.read(String)
              index_name = current_index_name if current_index_name == "test_index"
            end
          end

          index_name.should eq "test_index"

          index_columns = [] of String

          db.query(
            <<-SQL
              SELECT
                il.name AS index_name,
                ii.name AS column_name
              FROM
                sqlite_master AS m,
                pragma_index_list(m.name) AS il,
                pragma_index_info(il.name) AS ii
              WHERE
                m.type = 'table' AND
                m.tbl_name = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              rs.read(String)
              column_name = rs.read(String)
              index_columns << column_name
            end
          end

          index_columns.to_set.should eq ["foo", "bar"].to_set
        end
      end
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

    it "removes the index from the table" do
      index = Marten::DB::Management::Index.new("test_index", ["foo", "bar"])

      from_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        indexes: [index]
      )
      from_project_state = Marten::DB::Management::ProjectState.new([from_table_state])

      to_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )
      to_project_state = Marten::DB::Management::ProjectState.new([to_table_state])

      Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
        schema_editor.create_table(from_table_state)
      end

      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "operation_test_table",
        "test_index"
      )

      operation.mutate_db_forward(
        "my_app",
        Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default),
        from_project_state,
        to_project_state
      )

      index_names = [] of String

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          index_names = [] of String

          db.query(
            <<-SQL
              SHOW INDEX FROM operation_test_table;
            SQL
          ) do |rs|
            rs.each do
              rs.read(String) # table
              rs.read(Bool)   # non_unique
              index_names << rs.read(String)
            end
          end
        end

        for_postgresql do
          db.query(
            <<-SQL
              SELECT
                i.relname AS index_name,
                a.attname AS column_name
              FROM
                pg_class t,
                pg_class i,
                pg_index ix,
                pg_attribute a
              WHERE
                t.oid = ix.indrelid
                AND i.oid = ix.indexrelid
                AND a.attrelid = t.oid
                AND a.attnum = ANY(ix.indkey)
                AND t.relkind = 'r'
                AND t.relname = 'operation_test_table'
            SQL
          ) do |rs|
            rs.each do
              index_names << rs.read(String)
            end
          end
        end

        for_sqlite do
          db.query("PRAGMA index_list(operation_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              index_names << rs.read(String)
            end
          end
        end
      end

      index_names.includes?("test_index").should be_false
    end
  end

  describe "#mutate_state_forward" do
    it "mutates a project state as expected" do
      index = Marten::DB::Management::Index.new("test_index", ["foo", "bar"])

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        indexes: [index]
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "operation_test_table",
        "test_index"
      )

      operation.mutate_state_forward("my_app", project_state)

      table_state.indexes.should be_empty
    end
  end

  describe "#optimize" do
    it "returns the expected result if the other operation references the same table" do
      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "test_table",
        "test_index"
      )
      other_operation = Marten::DB::Migration::Operation::AddColumn.new(
        "test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      result = operation.optimize(other_operation)

      result.failed?.should be_true
    end

    it "returns the expected result if the other operation references another table" do
      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "test_table",
        "test_index"
      )
      other_operation = Marten::DB::Migration::Operation::AddColumn.new(
        "other_test_table",
        Marten::DB::Management::Column::BigInt.new("foo", null: false)
      )

      result = operation.optimize(other_operation)

      result.unchanged?.should be_true
    end
  end

  describe "#references_column?" do
    it "returns true if the specified column is in the same table" do
      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "test_table",
        "test_index"
      )

      operation.references_column?("test_table", "foo").should be_true
    end

    it "returns true if the specified column is in another table" do
      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "test_table",
        "test_index"
      )

      operation.references_column?("other_table", "foo").should be_false
    end
  end

  describe "#references_table?" do
    it "returns true if the specified table is the same" do
      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "test_table",
        "test_index"
      )

      operation.references_table?("test_table").should be_true
    end

    it "returns true if the specified table is not the same" do
      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "test_table",
        "test_index"
      )

      operation.references_table?("other_table").should be_false
    end
  end

  describe "#serialize" do
    it "returns the expected serialized version of the operation" do
      operation = Marten::DB::Migration::Operation::RemoveIndex.new(
        "my_table",
        "test_index"
      )
      operation.serialize.strip.should eq %{remove_index :my_table, :test_index}
    end
  end
end
