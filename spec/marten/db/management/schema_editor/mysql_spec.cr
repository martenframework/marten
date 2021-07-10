require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
  describe Marten::DB::Management::SchemaEditor::MySQL do
    describe "#column_type_for_built_in_column" do
      it "returns the expected column types" do
        schema_editor = Marten::DB::Connection.default.schema_editor

        expected_mapping = {
          "Marten::DB::Management::Column::Auto"       => "integer AUTO_INCREMENT",
          "Marten::DB::Management::Column::BigAuto"    => "bigint AUTO_INCREMENT",
          "Marten::DB::Management::Column::BigInt"     => "bigint",
          "Marten::DB::Management::Column::Bool"       => "bool",
          "Marten::DB::Management::Column::DateTime"   => "datetime(6)",
          "Marten::DB::Management::Column::ForeignKey" => "bigint",
          "Marten::DB::Management::Column::Int"        => "integer",
          "Marten::DB::Management::Column::String"     => "varchar(%{max_size})",
          "Marten::DB::Management::Column::Text"       => "longtext",
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
        Marten::DB::Management::Column.registry.values.each do |klass|
          schema_editor.column_type_suffix_for_built_in_column(klass.name).should be_nil
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
          "CREATE INDEX index_#{TestUser.db_table}_on_foo_bar ON `app_test_users` (`foo`, `bar`)"
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

        index_statement.to_s.should eq "CREATE INDEX index_name ON `app_test_users` (`foo`, `bar`)"
      end

      it "returns the expected index statement for a given table and columns when the index name is too long" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        columns = [
          Marten::DB::Management::Column::String.new("this_is_very_very_long_column_name", 255),
          Marten::DB::Management::Column::String.new("another_very_long_column_name", 128),
        ]

        index_statement = Marten::DB::Connection.default.schema_editor.create_index_deferred_statement(
          table_state,
          columns
        )

        index_name = index_statement.params["name"].to_s
        index_name.size.should be <= Marten::DB::Connection.default.max_name_size

        index_statement.to_s.should eq(
          "CREATE INDEX #{index_name} ON `app_test_users` (`this_is_very_very_long_column_name`, " \
          "`another_very_long_column_name`)"
        )
      end
    end

    describe "#ddl_rollbackable?" do
      it "returns false" do
        Marten::DB::Connection.default.schema_editor.ddl_rollbackable?.should be_false
      end
    end

    describe "#delete_column_statement" do
      it "returns the expected statement" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        column = Marten::DB::Management::Column::String.new("foo", 255)

        Marten::DB::Connection.default.schema_editor.delete_column_statement(table_state, column).should eq(
          "ALTER TABLE `#{TestUser.db_table}` DROP COLUMN `foo`"
        )
      end
    end

    describe "#delete_foreign_key_constraint_statement" do
      it "returns the expected statement" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        Marten::DB::Connection.default.schema_editor.delete_foreign_key_constraint_statement(table_state, "test")
          .should eq "ALTER TABLE `#{TestUser.db_table}` DROP CONSTRAINT `test`"
      end
    end

    describe "#delete_table_statement" do
      it "returns the expected statement" do
        Marten::DB::Connection.default.schema_editor.delete_table_statement("test_table").should eq(
          "DROP TABLE test_table CASCADE"
        )
      end
    end

    describe "#flush_tables_statements" do
      it "returns the expected statements" do
        Marten::DB::Connection.default.schema_editor.flush_tables_statements(["foo", "bar"]).should eq(
          [
            "SET FOREIGN_KEY_CHECKS = 0",
            "TRUNCATE foo",
            "TRUNCATE bar",
            "SET FOREIGN_KEY_CHECKS = 1",
          ]
        )
      end
    end

    describe "#prepare_foreign_key_for_new_column" do
      it "returns the expected statement" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        column = Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column"
        )

        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.prepare_foreign_key_for_new_column(table_state, column, "test bigint").should eq(
          "test bigint, " \
          "ADD CONSTRAINT `index_#{TestUser.db_table}_on_test_fk_other_table_other_column` " \
          "FOREIGN KEY (`test`) " \
          "REFERENCES `other_table` (`other_column`)"
        )
      end
    end

    describe "#prepare_foreign_key_for_new_table" do
      it "returns the initial column definition and generate a deferred statement to add the foreign key constraint" do
        table_state = Marten::DB::Management::TableState.from_model(TestUser)
        column = Marten::DB::Management::Column::ForeignKey.new(
          "test",
          to_table: "other_table",
          to_column: "other_column"
        )

        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.prepare_foreign_key_for_new_table(table_state, column, "test bigint").should eq "test bigint"

        statement = schema_editor.deferred_statements[0]

        statement.template.should eq(
          "ALTER TABLE %{table} " \
          "ADD CONSTRAINT %{constraint} " \
          "FOREIGN KEY (%{column}) " \
          "REFERENCES %{to_table} (%{to_column})"
        )

        statement.params["table"].should be_a Marten::DB::Management::Statement::Table
        table_statement = statement.params["table"].as(Marten::DB::Management::Statement::Table)
        table_statement.name.should eq TestUser.db_table

        statement.params["constraint"].should be_a Marten::DB::Management::Statement::ForeignKeyName
        fk_name_statement = statement.params["constraint"].as(Marten::DB::Management::Statement::ForeignKeyName)
        fk_name_statement.table.should eq TestUser.db_table
        fk_name_statement.column.should eq "test"
        fk_name_statement.to_table.should eq "other_table"
        fk_name_statement.to_column.should eq "other_column"

        statement.params["column"].should be_a Marten::DB::Management::Statement::Columns
        column_statement = statement.params["column"].as(Marten::DB::Management::Statement::Columns)
        column_statement.table.should eq TestUser.db_table
        column_statement.columns.should eq ["test"]

        statement.params["to_table"].should be_a Marten::DB::Management::Statement::Table
        to_table_statement = statement.params["to_table"].as(Marten::DB::Management::Statement::Table)
        to_table_statement.name.should eq "other_table"

        statement.params["to_column"].should be_a Marten::DB::Management::Statement::Columns
        to_column_statement = statement.params["to_column"].as(Marten::DB::Management::Statement::Columns)
        to_column_statement.table.should eq "other_table"
        to_column_statement.columns.should eq ["other_column"]
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
        schema_editor.quoted_default_value_for_built_in_column(local_time).should eq "'#{local_time}'"
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
      it "returns the expected statement" do
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
        schema_editor.remove_unique_constraint_statement(table_state, unique_constraint).should eq(
          "ALTER TABLE test_table DROP INDEX test_constraint"
        )
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
          "ALTER TABLE `#{TestUser.db_table}` CHANGE `test` `new_name` bigint NOT NULL"
        )
      end
    end

    describe "#rename_table_statement" do
      it "returns the expected statement" do
        Marten::DB::Connection.default.schema_editor.rename_table_statement("old_name", "new_name").should eq(
          "RENAME TABLE old_name TO new_name"
        )
      end
    end
  end
{% end %}
