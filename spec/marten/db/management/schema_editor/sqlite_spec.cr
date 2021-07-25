require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "sqlite" || !env("MARTEN_SPEC_DB_CONNECTION") %}
  describe Marten::DB::Management::SchemaEditor::SQLite do
    describe "#column_type_for_built_in_column" do
      it "returns the expected column types" do
        schema_editor = Marten::DB::Connection.default.schema_editor

        expected_mapping = {
          "Marten::DB::Management::Column::Auto"       => "integer",
          "Marten::DB::Management::Column::BigAuto"    => "integer",
          "Marten::DB::Management::Column::BigInt"     => "integer",
          "Marten::DB::Management::Column::Bool"       => "bool",
          "Marten::DB::Management::Column::DateTime"   => "datetime",
          "Marten::DB::Management::Column::ForeignKey" => "integer",
          "Marten::DB::Management::Column::Int"        => "integer",
          "Marten::DB::Management::Column::String"     => "varchar(%{max_size})",
          "Marten::DB::Management::Column::Text"       => "text",
          "Marten::DB::Management::Column::UUID"       => "char(32)",
        }

        expected_mapping.each do |column_id, column_type|
          schema_editor.column_type_for_built_in_column(column_id).should eq column_type
        end
      end
    end

    describe "#column_type_suffix_for_built_in_column" do
      it "returns nil" do
        schema_editor = Marten::DB::Connection.default.schema_editor

        expected_mapping = {
          "Marten::DB::Management::Column::Auto"       => "AUTOINCREMENT",
          "Marten::DB::Management::Column::BigAuto"    => "AUTOINCREMENT",
          "Marten::DB::Management::Column::BigInt"     => nil,
          "Marten::DB::Management::Column::Bool"       => nil,
          "Marten::DB::Management::Column::DateTime"   => nil,
          "Marten::DB::Management::Column::ForeignKey" => nil,
          "Marten::DB::Management::Column::Int"        => nil,
          "Marten::DB::Management::Column::String"     => nil,
          "Marten::DB::Management::Column::Text"       => nil,
          "Marten::DB::Management::Column::UUID"       => nil,
        }

        expected_mapping.each do |column_id, column_suffix|
          schema_editor.column_type_suffix_for_built_in_column(column_id).should eq column_suffix
        end
      end
    end

    describe "#create_table_statement" do
      it "returns the expected statement" do
        statement = Marten::DB::Connection.default.schema_editor.create_table_statement(
          "my_table",
          ["last_name varchar(255)", "first_name varchar(255)"].join(", ")
        )
        statement.should eq "CREATE TABLE my_table (last_name varchar(255), first_name varchar(255))"
      end
    end

    describe "#create_index_deferred_statement" do
      it "returns the expected index statement for a given table and columns" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        columns = [
          Marten::DB::Management::Column::String.new("foo", 255),
          Marten::DB::Management::Column::String.new("bar", 128),
        ]

        index_statement = Marten::DB::Connection.default.schema_editor.create_index_deferred_statement(
          table_state,
          columns
        )

        index_statement.to_s.should eq(
          "CREATE INDEX index_app_test_users_on_foo_bar ON \"app_test_users\" (\"foo\", \"bar\")"
        )
      end

      it "returns the expected index statement for a given set of table, columns and fixed name" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        columns = [
          Marten::DB::Management::Column::String.new("foo", 255),
          Marten::DB::Management::Column::String.new("bar", 128),
        ]

        index_statement = Marten::DB::Connection.default.schema_editor.create_index_deferred_statement(
          table_state,
          columns,
          name: "index_name"
        )

        index_statement.to_s.should eq "CREATE INDEX index_name ON \"app_test_users\" (\"foo\", \"bar\")"
      end

      it "returns the expected index statement for a given table and columns when the index name is too long" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        columns = [
          Marten::DB::Management::Column::String.new("this_is_very_very_long_column_name", 255),
          Marten::DB::Management::Column::String.new("another_very_long_column_name", 128),
          Marten::DB::Management::Column::String.new("another_very_long_column_name2", 128),
          Marten::DB::Management::Column::String.new("another_very_long_column_name3", 128),
        ]

        index_statement = Marten::DB::Connection.default.schema_editor.create_index_deferred_statement(
          table_state,
          columns
        )

        index_name = index_statement.params["name"].to_s
        index_name.size.should be <= Marten::DB::Connection.default.max_name_size

        index_statement.to_s.should eq(
          "CREATE INDEX #{index_name} ON \"app_test_users\" (\"this_is_very_very_long_column_name\", " \
          "\"another_very_long_column_name\", \"another_very_long_column_name2\", " \
          "\"another_very_long_column_name3\")"
        )
      end
    end

    describe "#ddl_rollbackable?" do
      it "returns true" do
        Marten::DB::Connection.default.schema_editor.ddl_rollbackable?.should be_true
      end
    end

    describe "#delete_column_statement" do
      it "raises NotImplementedError" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        column = Marten::DB::Management::Column::String.new("foo", 255)

        expect_raises(NotImplementedError) do
          Marten::DB::Connection.default.schema_editor.delete_column_statement(table_state, column)
        end
      end
    end

    describe "#delete_foreign_key_constraint_statement" do
      it "raises NotImplementedError the expected statement" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)

        expect_raises(NotImplementedError) do
          Marten::DB::Connection.default.schema_editor.delete_foreign_key_constraint_statement(table_state, "test")
        end
      end
    end

    describe "#delete_table_statement" do
      it "returns the expected statement" do
        Marten::DB::Connection.default.schema_editor.delete_table_statement("test_table").should eq(
          "DROP TABLE test_table"
        )
      end
    end

    describe "#flush_tables_statements" do
      it "returns the expected statements" do
        Marten::DB::Connection.default.schema_editor.flush_tables_statements(["foo", "bar"]).should eq(
          [
            "DELETE FROM foo",
            "DELETE FROM bar",
            "UPDATE \"sqlite_sequence\" SET \"seq\" = 0 WHERE \"name\" IN (foo, bar)",
          ]
        )
      end
    end

    describe "#prepare_foreign_key_for_new_column" do
      it "raises NotImplementedError" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        column = Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column"
        )

        schema_editor = Marten::DB::Connection.default.schema_editor
        expect_raises(NotImplementedError) do
          schema_editor.prepare_foreign_key_for_new_column(table_state, column, "test bigint")
        end
      end
    end

    describe "#prepare_foreign_key_for_new_table" do
      it "returns the expected statement" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        column = Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column"
        )

        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.prepare_foreign_key_for_new_table(table_state, column, "test bigint").should eq(
          "test bigint " \
          "REFERENCES \"other_table\" (\"other_column\") " \
          "DEFERRABLE INITIALLY DEFERRED"
        )
      end
    end

    describe "#quoted_default_value_for_built_in_column" do
      it "returns the expected string representation for a byte value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column(Bytes[255, 97]).should eq "X'ff61'"
      end

      it "returns the expected string representation for a string value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column("hello").should eq "'hello'"
        schema_editor.quoted_default_value_for_built_in_column(%{value " quote}).should eq "'value \" quote'"
      end

      it "returns the expected string representation for a time value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        local_time = Time.local
        schema_editor.quoted_default_value_for_built_in_column(local_time).should eq(
          "'#{local_time.to_utc.to_s("%F %H:%M:%S.%L")}'"
        )
      end

      it "returns the expected string representation for a bool value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column(false).should eq "0"
        schema_editor.quoted_default_value_for_built_in_column(true).should eq "1"
      end

      it "returns the expected string representation for an integer value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column(42).should eq "42"
      end

      it "returns the expected string representation for a float value" do
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.quoted_default_value_for_built_in_column(42.44).should eq "42.44"
      end
    end

    describe "#remove_unique_constraint_statement" do
      it "raises NotImplementedError" do
        unique_constraint = Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])
        table_state = Marten::DB::Management::TableState.new(
          "my_app",
          "test_table",
          columns: [
            Marten::DB::Management::Column::BigAuto.new("test", primary_key: true),
            Marten::DB::Management::Column::BigInt.new("foo"),
            Marten::DB::Management::Column::BigInt.new("bar"),
          ] of Marten::DB::Management::Column::Base,
          unique_constraints: [unique_constraint]
        )

        schema_editor = Marten::DB::Connection.default.schema_editor

        expect_raises(NotImplementedError) do
          schema_editor.remove_unique_constraint_statement(table_state, unique_constraint.name)
        end
      end
    end

    describe "#rename_column_statement" do
      it "returns the expected statement" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        column = Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column"
        )

        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.rename_column_statement(table_state, column, "new_name").should eq(
          "ALTER TABLE \"#{TestUser.db_table}\" RENAME COLUMN \"test\" TO \"new_name\""
        )
      end
    end

    describe "#rename_table_statement" do
      it "returns the expected statement" do
        Marten::DB::Connection.default.schema_editor.rename_table_statement("old_name", "new_name").should eq(
          "ALTER TABLE old_name RENAME TO new_name"
        )
      end
    end
  end
{% end %}
