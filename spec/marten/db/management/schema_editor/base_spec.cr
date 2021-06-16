require "./spec_helper"

describe Marten::DB::Management::SchemaEditor::Base do
  describe "#add_column" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("schema_editor_test_table")))
      end
    end

    it "can add a simple column to an existing table" do
      schema_editor = Marten::DB::Connection.default.schema_editor

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo"))

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.should eq "int(11)"
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type
              FROM information_schema.columns
              WHERE table_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.should eq "integer"
            end
          end
        {% else %}
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.should eq "integer"
            end
          end
        {% end %}
      end
    end

    it "can add a column with a default value to an existing table" do
      schema_editor = Marten::DB::Connection.default.schema_editor

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", default: 42))

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT #{schema_editor.quote("foo")} FROM #{schema_editor.quote("schema_editor_test_table")}") do |rs|
          rs.each do
            value = rs.read(Int32 | Int64)
            value.should eq 42
          end
        end
      end
    end

    it "can add a nullable column to an existing table" do
      schema_editor = Marten::DB::Connection.default.schema_editor

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", null: true))

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              rs.read(String)
              nullable = rs.read(String)
              nullable.should eq "YES"
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, is_nullable
              FROM information_schema.columns
              WHERE table_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              nullable = rs.read(String)
              nullable.should eq "YES"
            end
          end
        {% else %}
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              next unless column_name == "foo"
              rs.read(String)
              not_null = rs.read(Int32)
              not_null.should eq 0
            end
          end
        {% end %}
      end
    end

    it "can add a non-nullable column to an existing table" do
      schema_editor = Marten::DB::Connection.default.schema_editor

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", null: false))

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              rs.read(String)
              nullable = rs.read(String)
              nullable.should eq "NO"
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, is_nullable
              FROM information_schema.columns
              WHERE table_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              nullable = rs.read(String)
              nullable.should eq "NO"
            end
          end
        {% else %}
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              next unless column_name == "foo"
              rs.read(String)
              not_null = rs.read(Int32)
              not_null.should eq 1
            end
          end
        {% end %}
      end
    end

    it "can add a primary key column to an existing table" do
      schema_editor = Marten::DB::Connection.default.schema_editor

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
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              2.times { rs.read(String) }
              primary_key = rs.read(String)
              primary_key.should eq "PRI"
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
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
        {% else %}
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
        {% end %}
      end
    end

    it "can add a non-primary key column to an existing table" do
      schema_editor = Marten::DB::Connection.default.schema_editor

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
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              2.times { rs.read(String) }
              primary_key = rs.read(String)
              primary_key.should be_empty
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
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
        {% else %}
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
        {% end %}
      end
    end

    it "can add a unique column to an existing table" do
      schema_editor = Marten::DB::Connection.default.schema_editor

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", unique: true))

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
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
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
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
        {% else %}
          db.query("PRAGMA index_list(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              rs.read(String)
              unique = rs.read(Int32 | Int64)
              unique.should eq 1
            end
          end
        {% end %}
      end
    end

    it "can add a foreign key column to an existing table" do
      schema_editor = Marten::DB::Connection.default.schema_editor

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)
      schema_editor.add_column(
        table_state,
        Marten::DB::Management::Column::ForeignKey.new("foo", TestUser.db_table, "id")
      )

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.should eq "bigint(20)"
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
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
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
        {% else %}
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              next unless column_name == "foo"
              column_type = rs.read(String)
              column_type.should eq "integer"
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
        {% end %}
      end
    end

    {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" || env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
      it "generates a deferred statement if the column is indexed" do
        schema_editor = Marten::DB::Connection.default.schema_editor

        table_state = Marten::DB::Management::TableState.new(
          "my_app",
          "schema_editor_test_table",
          columns: [
            Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
          ] of Marten::DB::Management::Column::Base,
          unique_constraints: [] of Marten::DB::Management::Constraint::Unique
        )

        schema_editor.create_table(table_state)
        schema_editor.add_column(table_state, Marten::DB::Management::Column::Int.new("foo", index: true, default: 42))

        schema_editor.deferred_statements.size.should eq 1
        schema_editor.deferred_statements.first.params["name"].should be_a Marten::DB::Management::Statement::IndexName
      end
    {% end %}
  end

  describe "#create_model" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_model_table")
        schema_editor.execute(
          schema_editor.delete_table_statement(
            schema_editor.quote("schema_editor_test_model_table")
          )
        )
      end
    end

    it "is able to create the table corresponding to a given model" do
      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_model(Marten::DB::Management::BaseSpec::TestModel)

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_model_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              column_type = rs.read(String)
              nullable = rs.read(String)
              key = rs.read(String)
              default = rs.read(Nil | String)

              if column_name == "foo"
                column_type.should eq "int(11)"
                nullable.should eq "NO"
                key.should be_empty
                default.should eq "42"
              elsif column_name == "id"
                column_type.should eq "bigint(20)"
                nullable.should eq "NO"
                key.should eq "PRI"
                default.should be_nil
              end
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'schema_editor_test_model_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              column_type = rs.read(String)
              nullable = rs.read(String)
              default = rs.read(String)

              if column_name == "foo"
                column_type.should eq "integer"
                nullable.should eq "NO"
                default.should eq "42"
              elsif column_name == "id"
                column_type.should eq "bigint"
                nullable.should eq "NO"
                default.starts_with?("nextval").should be_true
              end
            end
          end
        {% else %}
          db.query("PRAGMA table_info(schema_editor_test_model_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)

              column_name = rs.read(String)
              column_type = rs.read(String)
              not_null = rs.read(Int32 | Int64)
              default_value = rs.read(Nil | String)
              primary_key = rs.read(Int32 | Int64)

              if column_name == "foo"
                column_type.should eq "integer"
                not_null.should eq 1
                default_value.should eq "42"
                primary_key.should eq 0
              elsif column_name == "id"
                column_type.should eq "integer"
                not_null.should eq 1
                default_value.should be_nil
                primary_key.should eq 1
              end
            end
          end
        {% end %}
      end
    end
  end

  describe "#create_table" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("schema_editor_test_table")))
      end
    end

    it "is able to create a new table" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::Int.new("foo", default: 42),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(table_state)

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              column_type = rs.read(String)
              nullable = rs.read(String)
              key = rs.read(String)
              default = rs.read(Nil | String)

              if column_name == "foo"
                column_type.should eq "int(11)"
                nullable.should eq "NO"
                key.should be_empty
                default.should eq "42"
              elsif column_name == "id"
                column_type.should eq "bigint(20)"
                nullable.should eq "NO"
                key.should eq "PRI"
                default.should be_nil
              end
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              column_type = rs.read(String)
              nullable = rs.read(String)
              default = rs.read(String)

              if column_name == "foo"
                column_type.should eq "integer"
                nullable.should eq "NO"
                default.should eq "42"
              elsif column_name == "id"
                column_type.should eq "bigint"
                nullable.should eq "NO"
                default.starts_with?("nextval").should be_true
              end
            end
          end
        {% else %}
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)

              column_name = rs.read(String)
              column_type = rs.read(String)
              not_null = rs.read(Int32 | Int64)
              default_value = rs.read(Nil | String)
              primary_key = rs.read(Int32 | Int64)

              if column_name == "foo"
                column_type.should eq "integer"
                not_null.should eq 1
                default_value.should eq "42"
                primary_key.should eq 0
              elsif column_name == "id"
                column_type.should eq "integer"
                not_null.should eq 1
                default_value.should be_nil
                primary_key.should eq 1
              end
            end
          end
        {% end %}
      end
    end

    it "properly creates unique constraints" do
      schema_editor = Marten::DB::Connection.default.schema_editor

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [
          Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
        ]
      )

      schema_editor.create_table(table_state)

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
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
              WHERE TABLE_NAME = 'schema_editor_test_table';
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
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
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
              WHERE contype = 'u' AND ccu.table_name = 'schema_editor_test_table'
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
        {% else %}
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
        {% end %}
      end
    end

    it "generates a deferred statement for indexed columns" do
      schema_editor = Marten::DB::Connection.default.schema_editor

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
          Marten::DB::Management::Column::BigInt.new("foo", index: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor.create_table(table_state)

      schema_editor.deferred_statements.size.should eq 1
      schema_editor.deferred_statements.first.params["name"].should be_a Marten::DB::Management::Statement::IndexName
    end

    {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" || env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
      it "generates a deferred statement for foreign key columns" do
        schema_editor = Marten::DB::Connection.default.schema_editor

        table_state = Marten::DB::Management::TableState.new(
          "my_app",
          "schema_editor_test_table",
          columns: [
            Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
            Marten::DB::Management::Column::ForeignKey.new("foo", TestUser.db_table, "id"),
          ] of Marten::DB::Management::Column::Base,
          unique_constraints: [] of Marten::DB::Management::Constraint::Unique
        )

        schema_editor.create_table(table_state)

        schema_editor.deferred_statements.size.should eq 2
        schema_editor.deferred_statements.first.params["constraint"].should be_a(
          Marten::DB::Management::Statement::ForeignKeyName
        )
      end
    {% end %}
  end

  describe "#delete_model" do
    it "deletes the table associated with a given model" do
      Marten::DB::Connection.default.schema_editor.delete_model(Marten::DB::Management::BaseSpec::TestModel)
      Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_model_table")
        .should be_false
      Marten::DB::Connection.default.schema_editor.create_model(Marten::DB::Management::BaseSpec::TestModel)
    end
  end

  describe "#delete_table" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("schema_editor_test_table")))
      end
    end

    it "deletes the considered table" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::Int.new("foo", default: 42),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(table_state)

      schema_editor.delete_table(table_state)

      Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_table").should be_false
    end
  end

  describe "#remove_column" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("schema_editor_test_table")))
      end
    end

    it "removes a column from a specific table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(table_state)

      schema_editor.remove_column(table_state, column)

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              column_name.should eq "id"
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              column_name.should eq "id"
            end
          end
        {% else %}
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              column_name.should eq "id"
            end
          end
        {% end %}
      end
    end

    it "removes a foreign key column from a specific table" do
      column = Marten::DB::Management::Column::ForeignKey.new("foo", TestUser.db_table, "id")
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(table_state)

      schema_editor.remove_column(table_state, column)

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_name = rs.read(String)
              column_name.should eq "id"
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_name = rs.read(String)
              column_name.should eq "id"
            end
          end
        {% else %}
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_name = rs.read(String)
              column_name.should eq "id"
            end
          end
        {% end %}
      end
    end

    {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" || env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
      it "removes deferred statements referencing the removed column" do
        column = Marten::DB::Management::Column::Int.new("foo", default: 42)
        table_state = Marten::DB::Management::TableState.new(
          "my_app",
          "schema_editor_test_table",
          columns: [
            Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
            column,
          ] of Marten::DB::Management::Column::Base,
          unique_constraints: [] of Marten::DB::Management::Constraint::Unique
        )

        Marten::DB::Connection.default.schema_editor.create_table(table_state)

        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
          "tpl1",
          column: Marten::DB::Management::Statement::Columns.new(
            ->schema_editor.quote(String),
            "schema_editor_test_table",
            ["foo"],
          )
        )
        schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
          "tpl2",
          column: Marten::DB::Management::Statement::Columns.new(
            ->schema_editor.quote(String),
            "schema_editor_test_table",
            ["bar"],
          )
        )

        schema_editor.remove_column(table_state, column)

        schema_editor.deferred_statements.size.should eq 1
        schema_editor.deferred_statements.first.template.should eq "tpl2"
      end
    {% end %}
  end

  describe "#rename_column" do
    before_each do
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("schema_editor_test_table")))
      end
    end

    it "renames a column in a specific table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(table_state)

      schema_editor.rename_column(table_state, column, "new_name")

      column_names = [] of String

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM schema_editor_test_table") do |rs|
            rs.each do
              column_names << rs.read(String)
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              column_names << rs.read(String)
            end
          end
        {% else %}
          db.query("PRAGMA table_info(schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_names << rs.read(String)
            end
          end
        {% end %}
      end

      column_names.to_set.should eq ["id", "new_name"].to_set
    end

    it "mutates deferred deferred statements referencing the renamed column" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      Marten::DB::Connection.default.schema_editor.create_table(table_state)

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
        "tpl1",
        column: Marten::DB::Management::Statement::Columns.new(
          ->schema_editor.quote(String),
          "schema_editor_test_table",
          ["foo"],
        )
      )
      schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
        "tpl2",
        column: Marten::DB::Management::Statement::Columns.new(
          ->schema_editor.quote(String),
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
      schema_editor = Marten::DB::Connection.default.schema_editor
      if Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_table")
        schema_editor.execute(schema_editor.delete_table_statement(schema_editor.quote("schema_editor_test_table")))
      end

      if Marten::DB::Connection.default.introspector.table_names.includes?("renamed_schema_editor_test_table")
        schema_editor.execute(
          schema_editor.delete_table_statement(schema_editor.quote("renamed_schema_editor_test_table"))
        )
      end
    end

    it "renames a table" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(table_state)

      schema_editor.rename_table(table_state, "renamed_schema_editor_test_table")

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM renamed_schema_editor_test_table") do |rs|
            rs.each do
              rs.read(String).should eq "id"
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'renamed_schema_editor_test_table'
            SQL
          ) do |rs|
            rs.each do
              rs.read(String).should eq "id"
            end
          end
        {% else %}
          db.query("PRAGMA table_info(renamed_schema_editor_test_table)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              rs.read(String).should eq "id"
            end
          end
        {% end %}
      end
    end

    it "mutates deferred deferred statements referencing the renamed table" do
      column = Marten::DB::Management::Column::Int.new("foo", default: 42)
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "schema_editor_test_table",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          column,
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      Marten::DB::Connection.default.schema_editor.create_table(table_state)

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
        "tpl1",
        table: Marten::DB::Management::Statement::Table.new(
          ->schema_editor.quote(String),
          "schema_editor_test_table"
        )
      )
      schema_editor.deferred_statements << Marten::DB::Management::Statement.new(
        "tpl2",
        table: Marten::DB::Management::Statement::Table.new(
          ->schema_editor.quote(String),
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
end

module Marten::DB::Management::BaseSpec
  class TestModel < Marten::DB::Model
    field :id, :big_auto, primary_key: true
    field :foo, :int, default: 42

    db_table :schema_editor_test_model_table

    def self.app_config
      Marten.apps.app_configs.first
    end
  end
end
