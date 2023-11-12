require "./spec_helper"

describe Marten::DB::Management::SchemaEditor::Base do
  describe "#add_column" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "can add a simple column to an existing table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo"))

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      db_column = introspector.columns_details(table_state.name).find! { |c| c.name == "foo" }

      for_mysql { db_column.type.should eq "int" }
      for_postgresql { db_column.type.should eq "integer" }
      for_sqlite { db_column.type.downcase.should eq "integer" }
    end

    it "can add a column with a default value to an existing table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", default: 42))

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT foo FROM schema_editor_test_table") do |rs|
          rs.each do
            value = rs.read(Int32 | Int64)
            value.should eq 42
          end
        end
      end
    end

    it "can add a nullable column to an existing table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", null: true))

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      db_column = introspector.columns_details(table_state.name).find! { |c| c.name == "foo" }

      db_column.nullable?.should be_true
    end

    it "can add a non-nullable column to an existing table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", null: false))

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      db_column = introspector.columns_details(table_state.name).find! { |c| c.name == "foo" }

      db_column.nullable?.should be_false
    end

    it "can add a primary key column to an existing table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::Int.new("test"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", primary_key: true))

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              2.times { rs.read(String) }
              primary_key = rs.read(String)
              primary_key.should eq "PRI"
            end
          end
        end

        for_postgresql do
          db.query(
            <<-SQL
            SELECT a.attname
            FROM pg_index i
            JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
            WHERE i.indrelid = 'schema_editor_test_table'::regclass AND i.indisprimary;
            SQL
          ) do |rs|
            rs.each do
              rs.read(String).should eq "foo"
            end
          end
        end

        for_sqlite do
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              next unless column_name == "foo"
              3.times { rs.read(String | Int64 | Nil) }
              primary_key = rs.read(Int64)
              primary_key.should eq 1
            end
          end
        end
      end
    end

    it "can add a non-primary key column to an existing table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::Int.new("test", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", primary_key: false))

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              2.times { rs.read(String) }
              primary_key = rs.read(String)
              primary_key.should be_empty
            end
          end
        end

        for_postgresql do
          db.query(
            <<-SQL
            SELECT a.attname
            FROM pg_index i
            JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
            WHERE i.indrelid = 'schema_editor_test_table'::regclass AND i.indisprimary;
            SQL
          ) do |rs|
            rs.each do
              rs.read(String).should eq "test"
            end
          end
        end

        for_sqlite do
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              next unless column_name == "foo"
              3.times { rs.read(String | Int64 | Nil) }
              primary_key = rs.read(Int64)
              primary_key.should eq 0
            end
          end
        end
      end
    end

    it "can add a unique column to an existing table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", unique: true))

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query(
            <<-SQL
              SELECT
                CONSTRAINT_NAME,
                CONSTRAINT_TYPE
              FROM information_schema.TABLE_CONSTRAINTS
              WHERE TABLE_NAME = 'schema_editor_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              next unless constraint_name == "foo"
              constraint_type = rs.read(String)
              constraint_type.should eq "UNIQUE"
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
              WHERE rel.relname = 'schema_editor_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              next unless constraint_name == "schema_editor_test_table_foo_key"
              constraint_type = rs.read(Char)
              constraint_type.should eq 'u'
            end
          end
        end

        for_sqlite do
          db.query("PRAGMA index_list(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              rs.read(String)
              unique = rs.read(Int32 | Int64)
              unique.should eq 1
            end
          end
        end
      end
    end

    it "can add a foreign key column to an existing table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      new_column = Marten::DB::Management::Column::Reference.new("foo", TestUser.db_table, "id")
      new_column.contribute_to_project(project_state)

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, new_column)

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              ["bigint(20)", "bigint"].includes?(column_type).should be_true
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

    it "can add a non-foreign key reference column to an existing table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      new_column = Marten::DB::Management::Column::Reference.new("foo", TestUser.db_table, "id", foreign_key: false)
      new_column.contribute_to_project(project_state)

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, new_column)

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              ["bigint(20)", "bigint"].includes?(column_type).should be_true
            end
          end

          db.query(
            "SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME " \
            "FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE " \
            "WHERE REFERENCED_TABLE_NAME = '#{TestUser.db_table}' AND REFERENCED_COLUMN_NAME = 'id'"
          ) do |rs|
            rs.each do
              table_name = rs.read(String)
              column_name = rs.read(String)
              table_name.should_not eq "schema_editor_test_table"
              column_name.should_not eq "foo"
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
              column_name.should_not eq "foo"

              to_table = rs.read(String)
              to_table.should_not eq TestUser.db_table
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
              to_table.should_not eq TestUser.db_table

              from_column = rs.read(String)
              from_column.should_not eq "foo"

              to_column = rs.read(String)
              to_column.should_not eq "id"
            end
          end
        end
      end
    end

    for_db_backends :mysql, :postgresql do
      it "generates a deferred statement if the column is indexed" do
        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

        table_state = Marten::DB::Management::TableState.new(
          "my_app",
          "schema_editor_test_table",
          columns: [
            Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          ] of Marten::DB::Management::Column::Base,
          unique_constraints: [] of Marten::DB::Management::Constraint::Unique
        )

        schema_editor.create_table(table_state)
        schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", index: true, default: 42))

        schema_editor.deferred_statements.size.should eq 1
        schema_editor.deferred_statements.first.params["name"].should be_a Marten::DB::Management::Statement::IndexName
      end
    end
  end

  describe "#add_index" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "adds an index to a table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )

      schema_editor.create_table(table_state)

      schema_editor.add_index(
        table_state,
        Marten::DB::Management::Index.new("index_name", ["foo", "bar"])
      )

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          index_name = nil
          index_columns = [] of String

          db.query(
            <<-SQL
              SHOW INDEX FROM schema_editor_test_table;
            SQL
          ) do |rs|
            rs.each do
              rs.read(String) # table
              rs.read(Bool)   # non_unique

              current_index_name = rs.read(String)
              next unless current_index_name == "index_name"

              index_name = current_index_name

              rs.read(Int32 | Int64) # seq_in_index

              index_columns << rs.read(String)
            end
          end

          index_name.should eq "index_name"
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
                AND t.relname = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              current_index_name = rs.read(String)
              next unless current_index_name == "index_name"

              index_name = current_index_name
              index_columns << rs.read(String)
            end
          end

          index_name.should eq "index_name"
          index_columns.to_set.should eq ["foo", "bar"].to_set
        end

        for_sqlite do
          index_name = nil

          db.query("PRAGMA index_list(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              current_index_name = rs.read(String)
              index_name = current_index_name if current_index_name == "index_name"
            end
          end

          index_name.should eq "index_name"

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
                m.tbl_name = 'schema_editor_test_table'
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

  describe "#add_unique_constraint" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "adds a unique constraint to a table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)

      schema_editor.add_unique_constraint(
        table_state,
        Marten::DB::Management::Constraint::Unique.new("test_constraint_to_add", ["foo", "bar"])
      )

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query(
            <<-SQL
              SELECT
                CONSTRAINT_NAME,
                CONSTRAINT_TYPE
              FROM information_schema.TABLE_CONSTRAINTS
              WHERE TABLE_NAME = 'schema_editor_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              next unless constraint_name == "test_constraint_to_add"
              constraint_type = rs.read(String)
              constraint_type.should eq "UNIQUE"
            end
          end

          constraint_columns = [] of String

          db.query(
            <<-SQL
              SELECT COLUMN_NAME, CONSTRAINT_NAME
              FROM information_schema.KEY_COLUMN_USAGE
              WHERE TABLE_NAME = 'schema_editor_test_table';
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              constraint_name = rs.read(String)
              next unless constraint_name == "test_constraint_to_add"
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
              WHERE rel.relname = 'schema_editor_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              next unless constraint_name == "test_constraint_to_add"
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
              WHERE contype = 'u' AND ccu.table_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              column_name = rs.read(String)
              next unless constraint_name == "test_constraint_to_add"
              constraint_columns << column_name
            end
          end

          constraint_columns.to_set.should eq ["foo", "bar"].to_set
        end

        for_sqlite do
          db.query("PRAGMA index_list(schema_editor_test_table)") do |rs|
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
                m.tbl_name = 'schema_editor_test_table'
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

  describe "#create_table" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "is able to create a new table" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo", default: 42),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(table_state)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      columns_details = introspector.columns_details(table_state.name)
      columns_details.sort_by!(&.name)

      for_mysql do
        columns_details[0].name.should eq "foo"
        columns_details[0].type.should eq "int"
        columns_details[0].nullable?.should be_false
        columns_details[0].default.should eq "42"

        columns_details[1].name.should eq "id"
        columns_details[1].type.should eq "bigint"
        columns_details[1].nullable?.should be_false
        columns_details[1].default.should be_nil
      end

      for_postgresql do
        columns_details[0].name.should eq "foo"
        columns_details[0].type.should eq "integer"
        columns_details[0].nullable?.should be_false
        columns_details[0].default.should eq "42"

        columns_details[1].name.should eq "id"
        columns_details[1].type.should eq "bigint"
        columns_details[1].nullable?.should be_false
        columns_details[1].default.to_s.starts_with?("nextval").should be_true
      end

      for_sqlite do
        columns_details[0].name.should eq "foo"
        columns_details[0].type.downcase.should eq "integer"
        columns_details[0].nullable?.should be_false
        columns_details[0].default.should eq "42"

        columns_details[1].name.should eq "id"
        columns_details[1].type.downcase.should eq "integer"
        columns_details[1].nullable?.should be_false
        columns_details[1].default.should be_nil
      end
    end

    it "properly creates unique constraints" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [
          Marten::DB::Management::Constraint::Unique.new("test_constraint_to_create", ["foo", "bar"]),
        ]
      )

      schema_editor.create_table(table_state)

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query(
            <<-SQL
              SELECT
                CONSTRAINT_NAME,
                CONSTRAINT_TYPE
              FROM information_schema.TABLE_CONSTRAINTS
              WHERE TABLE_NAME = 'schema_editor_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              next unless constraint_name == "test_constraint_to_create"
              constraint_type = rs.read(String)
              constraint_type.should eq "UNIQUE"
            end
          end

          constraint_columns = [] of String

          db.query(
            <<-SQL
              SELECT COLUMN_NAME, CONSTRAINT_NAME
              FROM information_schema.KEY_COLUMN_USAGE
              WHERE TABLE_NAME = 'schema_editor_test_table';
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              constraint_name = rs.read(String)
              next unless constraint_name == "test_constraint_to_create"
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
              WHERE rel.relname = 'schema_editor_test_table';
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              next unless constraint_name == "test_constraint_to_create"
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
              WHERE contype = 'u' AND ccu.table_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              constraint_name = rs.read(String)
              column_name = rs.read(String)
              next unless constraint_name == "test_constraint_to_create"
              constraint_columns << column_name
            end
          end

          constraint_columns.to_set.should eq ["foo", "bar"].to_set
        end

        for_sqlite do
          db.query("PRAGMA index_list(schema_editor_test_table)") do |rs|
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
                m.tbl_name = 'schema_editor_test_table'
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

    it "generates a deferred statement for indexed columns" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo", index: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)

      schema_editor.deferred_statements.size.should eq 1
      schema_editor.deferred_statements.first.params["name"].should be_a Marten::DB::Management::Statement::IndexName
    end

    it "generates a deferred statement for custom indexes" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        indexes: [
          Marten::DB::Management::Index.new("index_name", ["foo", "bar"]),
        ]
      )

      schema_editor.create_table(table_state)

      schema_editor.deferred_statements.size.should eq 1
      schema_editor.deferred_statements.first.params["name"].should eq "index_name"
    end

    it "properly creates custom indexes" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        indexes: [
          Marten::DB::Management::Index.new("index_name", ["foo", "bar"]),
        ]
      )

      Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
        schema_editor.create_table(table_state)
      end

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          index_name = nil
          index_columns = [] of String

          db.query(
            <<-SQL
              SHOW INDEX FROM schema_editor_test_table;
            SQL
          ) do |rs|
            rs.each do
              rs.read(String) # table
              rs.read(Bool)   # non_unique

              current_index_name = rs.read(String)
              next unless current_index_name == "index_name"

              index_name = current_index_name

              rs.read(Int32 | Int64) # seq_in_index

              index_columns << rs.read(String)
            end
          end

          index_name.should eq "index_name"
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
                AND t.relname = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              current_index_name = rs.read(String)
              next unless current_index_name == "index_name"

              index_name = current_index_name
              index_columns << rs.read(String)
            end
          end

          index_name.should eq "index_name"
          index_columns.to_set.should eq ["foo", "bar"].to_set
        end

        for_sqlite do
          index_name = nil

          db.query("PRAGMA index_list(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              current_index_name = rs.read(String)
              index_name = current_index_name if current_index_name == "index_name"
            end
          end

          index_name.should eq "index_name"

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
                m.tbl_name = 'schema_editor_test_table'
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

  describe "#delete_table" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "deletes the table associated with the passed name" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo", default: 42),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(table_state)

      schema_editor.delete_table(table_state.name)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      introspector.table_names.includes?("schema_editor_test_table").should be_false
    end
  end

  describe "#remove_column" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "removes a column from a specific table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(table_state)

      schema_editor.remove_column(table_state, column)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      columns_details = introspector.columns_details(table_state.name)
      columns_details.map(&.name).should eq ["id"]
    end

    it "removes a foreign key column from a specific table" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)

      column = Marten::DB::Management::Column::Reference.new("foo", TestUser.db_table, "id")
      column.contribute_to_project(project_state)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(table_state)

      schema_editor.remove_column(table_state, column)

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      columns_details = introspector.columns_details(table_state.name)
      columns_details.map(&.name).should eq ["id"]
    end

    for_db_backends :mysql, :postgresql do
      it "removes deferred statements referencing the removed column" do
        column = Marten::DB::Management::Column::Int.new("foo", default: 42)
        table_state = Marten::DB::Management::TableState.new(
          "my_app",
          "schema_editor_test_table",
          columns: [
            Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            column,
          ] of Marten::DB::Management::Column::Base,
          unique_constraints: [] of Marten::DB::Management::Constraint::Unique
        )

        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.create_table(table_state)

        schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
        schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
          "tpl1",
          column: Marten::DB::Management::Statement::Columns.new(
            ->(x : String) { x },
            "schema_editor_test_table",
            ["foo"],
          )
        )
        schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
          "tpl2",
          column: Marten::DB::Management::Statement::Columns.new(
            ->(x : String) { x },
            "schema_editor_test_table",
            ["bar"],
          )
        )

        schema_editor.remove_column(table_state, column)

        schema_editor.deferred_statements.size.should eq 1
        schema_editor.deferred_statements.first.template.should eq "tpl2"
      end
    end
  end

  describe "#remove_index" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "removes an index from a table" do
      index = Marten::DB::Management::Index.new("index_name", ["foo", "bar"])
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        indexes: [index]
      )

      Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
        schema_editor.create_table(table_state)
      end

      Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
        schema_editor.remove_index(table_state, index)
      end

      index_names = [] of String

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          index_names = [] of String

          db.query(
            <<-SQL
              SHOW INDEX FROM schema_editor_test_table;
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
                AND t.relname = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              index_names << rs.read(String)
            end
          end
        end

        for_sqlite do
          db.query("PRAGMA index_list(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              index_names << rs.read(String)
            end
          end
        end
      end

      index_names.includes?("index_name").should be_false
    end
  end

  describe "#remove_unique_constraint" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "remove a unique constraint from a table" do
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      unique_constraint = Marten::DB::Management::Constraint::Unique.new("test_constraint_to_remove", ["foo", "bar"])
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [unique_constraint]
      )

      schema_editor.create_table(table_state)

      schema_editor.remove_unique_constraint(table_state, unique_constraint)

      constraint_names = [] of String

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query(
            <<-SQL
              SELECT
                CONSTRAINT_NAME,
                CONSTRAINT_TYPE
              FROM information_schema.TABLE_CONSTRAINTS
              WHERE TABLE_NAME = 'schema_editor_test_table';
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
              WHERE rel.relname = 'schema_editor_test_table';
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
                m.tbl_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              constraint_names << rs.read(String)
            end
          end
        end
      end

      constraint_names.includes?("test_constraint_to_remove").should be_false
    end
  end

  describe "#rename_column" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    it "renames a column in a specific table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(table_state)

      schema_editor.rename_column(table_state, column, "new_name")

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      columns_details = introspector.columns_details(table_state.name)
      columns_details.map(&.name).sort!.should eq ["id", "new_name"]
    end

    it "mutates deferred deferred statements referencing the renamed column" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(table_state)

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
        "tpl1",
        column: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "schema_editor_test_table",
          ["foo"],
        )
      )
      schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
        "tpl2",
        column: Marten::DB::Management::Statement::Columns.new(
          ->(x : String) { x },
          "schema_editor_test_table",
          ["bar"],
        )
      )

      schema_editor.rename_column(table_state, column, "new_name")

      column_statement_1 = schema_editor.deferred_statements[0].params["column"].as(
        Marten::DB::Management::Statement::Columns
      )
      column_statement_1.columns.should eq ["new_name"]

      column_statement_2 = schema_editor.deferred_statements[1].params["column"].as(
        Marten::DB::Management::Statement::Columns
      )
      column_statement_2.columns.should eq ["bar"]
    end
  end

  describe "#rename_table" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end

      if introspector.table_names.includes?("renamed_schema_editor_test_table")
        schema_editor.delete_table("renamed_schema_editor_test_table")
      end
    end

    it "renames a table" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(table_state)

      schema_editor.rename_table(table_state, "renamed_schema_editor_test_table")

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      columns_details = introspector.columns_details("renamed_schema_editor_test_table")
      columns_details.map(&.name).should eq ["id"]
    end

    it "mutates deferred deferred statements referencing the renamed table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.create_table(table_state)

      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
      schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
        "tpl1",
        table: Marten::DB::Management::Statement::Table.new(
          ->(x : String) { x },
          "schema_editor_test_table"
        )
      )
      schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
        "tpl2",
        table: Marten::DB::Management::Statement::Table.new(
          ->(x : String) { x },
          "other_table"
        )
      )

      schema_editor.rename_table(table_state, "renamed_schema_editor_test_table")

      table_statement_1 = schema_editor.deferred_statements[0].params["table"].as(
        Marten::DB::Management::Statement::Table
      )
      table_statement_1.name.should eq "renamed_schema_editor_test_table"

      table_statement_2 = schema_editor.deferred_statements[1].params["table"].as(
        Marten::DB::Management::Statement::Table
      )
      table_statement_2.name.should eq "other_table"
    end
  end

  describe "#change_column" do
    before_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_other_test_table")
        schema_editor.delete_table("schema_editor_other_test_table")
      end
      if introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.delete_table("schema_editor_test_table")
      end
    end

    after_each do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
      schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)

      if introspector.table_names.includes?("schema_editor_other_test_table")
        schema_editor.delete_table("schema_editor_other_test_table")
      end
    end

    it "can perform a column alteration that simply sets a column as nullable" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", null: false)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", null: true)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find! { |c| c.name == "foo" }

      db_column.nullable?.should be_true
    end

    it "can perform a column alteration that simply sets a column as nullable when there are existing records" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", null: false)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", null: true)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      connection.open do |db|
        db.exec("INSERT INTO schema_editor_test_table (foo) VALUES (42)")
      end

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find! { |c| c.name == "foo" }

      db_column.nullable?.should be_true
    end

    it "can perform a column alteration that simply sets a column as not nullable" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", null: true)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", null: false)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find! { |c| c.name == "foo" }

      db_column.nullable?.should be_false
    end

    it "can perform a column alteration that simply sets a column as not nullable when there are existing records" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", null: true)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", null: false, default: 42)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      connection.open do |db|
        db.exec("INSERT INTO schema_editor_test_table (foo) VALUES (NULL)")
      end

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find! { |c| c.name == "foo" }

      db_column.nullable?.should be_false
      db_column.default.should eq "42"

      connection.open do |db|
        db.scalar("SELECT foo FROM schema_editor_test_table").should eq 42
      end
    end

    it "can perform a column alteration that removes a column index" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", index: true)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", index: false)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy

      introspector.index_names(table_state.name, "foo").should be_empty
    end

    it "can perform a column alteration that adds a column index" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", index: false)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", index: true)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy

      introspector.index_names(table_state.name, "foo").size.should eq 1
    end

    it "can perform a column alteration that adds a unique constraint" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", unique: false)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", unique: true)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      connection.open { |db| db.exec("INSERT INTO schema_editor_test_table (foo) VALUES (42)") }

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy

      introspector.unique_constraint_names(table_state.name, "foo").size.should eq 1
    end

    it "can perform a column alteration that removes a unique constraint" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", unique: true)
      new_column = Marten::DB::Management::Column::BigInt.new("foo", unique: false)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      connection.open { |db| db.exec("INSERT INTO schema_editor_test_table (foo) VALUES (42)") }

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy

      introspector.unique_constraint_names(table_state.name, "foo").should be_empty
    end

    it "can perform a column alteration that changes the column type precision for integers" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::Int.new("foo")
      new_column = Marten::DB::Management::Column::BigInt.new("foo")

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      connection.open { |db| db.exec("INSERT INTO schema_editor_test_table (foo) VALUES (42)") }

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy
      db_column = db_column.not_nil!

      for_mysql { db_column.type.should eq "bigint" }
      for_postgresql { db_column.type.should eq "bigint" }
      for_sqlite { db_column.type.downcase.should eq "integer" }

      connection.open do |db|
        db.scalar("SELECT foo FROM schema_editor_test_table").should eq 42
      end
    end

    it "can perform a column alteration that changes the maximum string size for string columns" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::String.new("foo", max_size: 155)
      new_column = Marten::DB::Management::Column::String.new("foo", max_size: 255)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      connection.open { |db| db.exec("INSERT INTO schema_editor_test_table (foo) VALUES ('hello')") }

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy
      db_column = db_column.not_nil!

      for_mysql do
        db_column.type.should eq "varchar"
        db_column.character_maximum_length.should eq 255
      end

      for_postgresql do
        db_column.type.should eq "character varying"
        db_column.character_maximum_length.should eq 255
      end

      for_sqlite { db_column.type.should eq "varchar(255)" }

      connection.open do |db|
        db.scalar("SELECT foo FROM schema_editor_test_table").should eq "hello"
      end
    end

    it "can perform a column alteration that changes a column from a string type to a text type" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::String.new("foo", max_size: 155)
      new_column = Marten::DB::Management::Column::Text.new("foo")

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      connection.open { |db| db.exec("INSERT INTO schema_editor_test_table (foo) VALUES ('hello')") }

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy
      db_column = db_column.not_nil!

      for_mysql { db_column.type.should eq "longtext" }
      for_postgresql { db_column.type.should eq "text" }
      for_sqlite { db_column.type.downcase.should eq "text" }

      connection.open do |db|
        db.scalar("SELECT foo FROM schema_editor_test_table").should eq "hello"
      end
    end

    it "can perform a column alteration that adds a default value" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo")
      new_column = Marten::DB::Management::Column::BigInt.new("foo", default: 42)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy
      db_column = db_column.not_nil!

      db_column.nullable?.should be_false
      db_column.default.should eq "42"
    end

    it "can perform a column alteration that removes a default value" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", default: 42)
      new_column = Marten::DB::Management::Column::BigInt.new("foo")

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      db_column = introspector.columns_details(table_state.name).find { |c| c.name == "foo" }
      db_column.should be_truthy
      db_column = db_column.not_nil!

      db_column.nullable?.should be_false
      db_column.default.should be_nil
    end

    it "can add a primary key constraint to a column" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo")
      new_column = Marten::DB::Management::Column::BigInt.new("foo", primary_key: true)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      for_db_backends :mysql, :postgresql do
        introspector.primary_key_constraint_names(table_state.name, "foo").size.should eq 1
      end

      for_sqlite do
        is_primary_key = false

        connection.open do |db|
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              5.times { rs.read(String | Int32 | Int64 | Nil) }
              is_primary_key = (rs.read(Int64) == 1)
            end
          end
        end

        is_primary_key.should be_true
      end
    end

    it "can remove a primary key constraint from a column" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("foo", primary_key: true)
      new_column = Marten::DB::Management::Column::BigInt.new("foo")

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          old_column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor.create_table(table_state)

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      for_db_backends :mysql, :postgresql do
        introspector.primary_key_constraint_names(table_state.name, "foo").should be_empty
      end

      for_sqlite do
        is_primary_key = true

        connection.open do |db|
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              5.times { rs.read(String | Int32 | Int64 | Nil) }
              is_primary_key = (rs.read(Int64) == 1)
            end
          end
        end

        is_primary_key.should be_false
      end
    end

    it "can change a primary key column type and update the incoming foreign keys accordingly" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)
      introspector = Marten::DB::Management::Introspector.for(connection)

      old_column = Marten::DB::Management::Column::BigInt.new("id", primary_key: true)
      new_column = Marten::DB::Management::Column::String.new("id", max_size: 255, primary_key: true)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          old_column,
        ] of Marten::DB::Management::Column::Base
      )
      other_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_other_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true),
          Marten::DB::Management::Column::Reference.new("table_id", "schema_editor_test_table", "id"),
        ] of Marten::DB::Management::Column::Base
      )
      project_state = Marten::DB::Management::ProjectState.new(
        [
          table_state,
          other_table_state,
        ]
      )

      schema_editor.create_table(table_state)
      schema_editor.create_table(other_table_state)

      schema_editor.change_column(project_state, table_state, old_column, new_column)

      pk_db_column = introspector.columns_details(table_state.name).find { |c| c.name == "id" }
      pk_db_column.should be_truthy
      pk_db_column = pk_db_column.not_nil!

      for_mysql do
        pk_db_column.type.should eq "varchar"
        pk_db_column.character_maximum_length.should eq 255
      end

      for_postgresql do
        pk_db_column.type.should eq "character varying"
        pk_db_column.character_maximum_length.should eq 255
      end

      for_sqlite { pk_db_column.type.should eq "varchar(255)" }

      fk_db_column = introspector.columns_details(other_table_state.name).find { |c| c.name == "table_id" }
      fk_db_column.should be_truthy
      fk_db_column = fk_db_column.not_nil!

      for_mysql do
        fk_db_column.type.should eq "varchar"
        fk_db_column.character_maximum_length.should eq 255
      end

      for_postgresql do
        fk_db_column.type.should eq "character varying"
        fk_db_column.character_maximum_length.should eq 255
      end

      for_sqlite { fk_db_column.type.should eq "varchar(255)" }
    end

    it "can remove a foreign key constraint from a reference column" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)

      old_column = Marten::DB::Management::Column::Reference.new(
        "table_id",
        "schema_editor_test_table",
        "id",
        foreign_key: true
      )
      new_column = Marten::DB::Management::Column::Reference.new(
        "table_id",
        "schema_editor_test_table",
        "id",
        foreign_key: false
      )

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base
      )
      other_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_other_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true),
          old_column,
        ] of Marten::DB::Management::Column::Base
      )
      project_state = Marten::DB::Management::ProjectState.new(
        [
          table_state,
          other_table_state,
        ]
      )

      old_column.contribute_to_project(project_state)
      new_column.contribute_to_project(project_state)

      schema_editor.create_table(table_state)
      schema_editor.create_table(other_table_state)

      schema_editor.change_column(project_state, other_table_state, old_column, new_column)

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query("SHOW COLUMNS FROM schema_editor_other_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "table_id"
              column_type = rs.read(String)
              ["bigint(20)", "bigint"].includes?(column_type).should be_true
            end
          end

          db.query(
            "SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME " \
            "FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE " \
            "WHERE REFERENCED_TABLE_NAME = 'schema_editor_test_table' AND REFERENCED_COLUMN_NAME = 'id'"
          ) do |rs|
            rs.each do
              table_name = rs.read(String)
              column_name = rs.read(String)
              table_name.should_not eq "schema_editor_other_test_table"
              column_name.should_not eq "table_id"
            end
          end
        end

        for_postgresql do
          db.query(
            "SELECT column_name, data_type FROM information_schema.columns " \
            "WHERE table_name = 'schema_editor_other_test_table'"
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "table_id"
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
              WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name='schema_editor_other_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              column_name.should_not eq "table_id"

              to_table = rs.read(String)
              to_table.should_not eq "schema_editor_test_table"
            end
          end
        end

        for_sqlite do
          db.query("PRAGMA table_info(schema_editor_other_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              next unless column_name == "table_id"
              column_type = rs.read(String)
              column_type.downcase.should eq "integer"
            end
          end

          db.query("PRAGMA foreign_key_list(schema_editor_other_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              rs.read(Int32 | Int64)

              to_table = rs.read(String)
              to_table.should_not eq "schema_editor_test_table"

              from_column = rs.read(String)
              from_column.should_not eq "table_id"

              to_column = rs.read(String)
              to_column.should_not eq "id"
            end
          end
        end
      end
    end

    it "can add a foreign key constraint to a reference column" do
      connection = Marten::DB::Connection.default
      schema_editor = Marten::DB::Management::SchemaEditor.for(connection)

      old_column = Marten::DB::Management::Column::Reference.new(
        "table_id",
        "schema_editor_test_table",
        "id",
        foreign_key: false
      )
      new_column = Marten::DB::Management::Column::Reference.new(
        "table_id",
        "schema_editor_test_table",
        "id",
        foreign_key: true
      )

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base
      )
      other_table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_other_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true),
          old_column,
        ] of Marten::DB::Management::Column::Base
      )
      project_state = Marten::DB::Management::ProjectState.new(
        [
          table_state,
          other_table_state,
        ]
      )

      old_column.contribute_to_project(project_state)
      new_column.contribute_to_project(project_state)

      schema_editor.create_table(table_state)
      schema_editor.create_table(other_table_state)

      schema_editor.change_column(project_state, other_table_state, old_column, new_column)

      Marten::DB::Connection.default.open do |db|
        for_mysql do
          db.query("SHOW COLUMNS FROM schema_editor_other_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "table_id"
              column_type = rs.read(String)
              ["bigint(20)", "bigint"].includes?(column_type).should be_true
            end
          end

          db.query(
            "SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME " \
            "FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE " \
            "WHERE REFERENCED_TABLE_NAME = 'schema_editor_test_table' AND REFERENCED_COLUMN_NAME = 'id'"
          ) do |rs|
            rs.each do
              table_name = rs.read(String)
              next unless table_name == "schema_editor_other_test_table"
              column_name = rs.read(String)
              column_name.should eq "table_id"
            end
          end
        end

        for_postgresql do
          db.query(
            "SELECT column_name, data_type FROM information_schema.columns " \
            "WHERE table_name = 'schema_editor_other_test_table'"
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "table_id"
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
              next unless column_name == "table_id"

              to_table = rs.read(String)
              to_table.should eq "schema_editor_test_table"

              to_column = rs.read(String)
              to_column.should eq "id"
            end
          end
        end

        for_sqlite do
          db.query("PRAGMA table_info(schema_editor_other_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              next unless column_name == "table_id"
              column_type = rs.read(String)
              column_type.downcase.should eq "integer"
            end
          end

          db.query("PRAGMA foreign_key_list(schema_editor_other_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              rs.read(Int32 | Int64)

              to_table = rs.read(String)
              to_table.should eq "schema_editor_test_table"

              from_column = rs.read(String)
              from_column.should eq "table_id"

              to_column = rs.read(String)
              to_column.should eq "id"
            end
          end
        end
      end
    end
  end
end
