require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
  describe Marten::DB::Management::SchemaEditor::MySQL do
    describe "#column_type_for_built_in_column" do
      it "returns the expected column type for a big int column" do
        column = Marten::DB::Management::Column::BigInt.new("test")
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "bigint"
      end

      it "returns the expected column type for a big int column with auto increment" do
        column = Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true)
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "bigint AUTO_INCREMENT"
      end

      it "returns the expected column type for a bool column" do
        column = Marten::DB::Management::Column::Bool.new("test")
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "bool"
      end

      it "returns the expected column type for a datetime column" do
        column = Marten::DB::Management::Column::DateTime.new("test")
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "datetime(6)"
      end

      it "returns the expected column type for a foreign key column" do
        column = Marten::DB::Management::Column::ForeignKey.new("test", to_table: "test", to_column: "test")
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "bigint"
      end

      it "returns the expected column type for an int column" do
        column = Marten::DB::Management::Column::Int.new("test")
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "integer"
      end

      it "returns the expected column type for an int column with auto increment" do
        column = Marten::DB::Management::Column::Int.new("test", primary_key: true, auto: true)
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "integer AUTO_INCREMENT"
      end

      it "returns the expected column type for a string column" do
        column = Marten::DB::Management::Column::String.new("test", max_size: 155)
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "varchar(%{max_size})"
      end

      it "returns the expected column type for a text column" do
        column = Marten::DB::Management::Column::Text.new("test")
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "longtext"
      end

      it "returns the expected column type for a uuid column" do
        column = Marten::DB::Management::Column::UUID.new("test")
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_for_built_in_column(column).should eq "char(32)"
      end
    end

    describe "#column_type_suffix_for_built_in_column" do
      it "returns nil" do
        column = Marten::DB::Management::Column::BigInt.new("test")
        schema_editor = Marten::DB::Connection.default.schema_editor
        schema_editor.column_type_suffix_for_built_in_column(column).should be_nil
      end
    end

    describe "#create_table" do
      before_each do
        schema_editor = Marten::DB::Connection.default.schema_editor
        if Marten::DB::Connection.default.introspector.table_names.includes?("schema_editor_test_table")
          schema_editor.delete_table("schema_editor_test_table")
        end
      end

      it "generates a deferred statement for foreign key columns" do
        schema_editor = Marten::DB::Connection.default.schema_editor

        table_state = Marten::DB::Management::TableState.new(
          "my_app",
          "schema_editor_test_table",
          columns: [
            Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
            Marten::DB::Management::Column::ForeignKey.new("foo", TestUser.db_table, "id"),
          ] of Marten::DB::Management::Column::Base,
          unique_constraints: [] of Marten::DB::Management::Constraint::Unique
        )

        schema_editor.create_table(table_state)

        statement = schema_editor.deferred_statements[0]

        statement.template.should eq(
          "ALTER TABLE %{table} " \
          "ADD CONSTRAINT %{constraint} " \
          "FOREIGN KEY (%{column}) " \
          "REFERENCES %{to_table} (%{to_column})"
        )

        statement.params["table"].should be_a Marten::DB::Management::Statement::Table
        table_statement = statement.params["table"].as(Marten::DB::Management::Statement::Table)
        table_statement.name.should eq "schema_editor_test_table"

        statement.params["constraint"].should be_a Marten::DB::Management::Statement::ForeignKeyName
        fk_name_statement = statement.params["constraint"].as(Marten::DB::Management::Statement::ForeignKeyName)
        fk_name_statement.table.should eq "schema_editor_test_table"
        fk_name_statement.column.should eq "foo"
        fk_name_statement.to_table.should eq TestUser.db_table
        fk_name_statement.to_column.should eq "id"

        statement.params["column"].should be_a Marten::DB::Management::Statement::Columns
        column_statement = statement.params["column"].as(Marten::DB::Management::Statement::Columns)
        column_statement.table.should eq "schema_editor_test_table"
        column_statement.columns.should eq ["foo"]

        statement.params["to_table"].should be_a Marten::DB::Management::Statement::Table
        to_table_statement = statement.params["to_table"].as(Marten::DB::Management::Statement::Table)
        to_table_statement.name.should eq TestUser.db_table

        statement.params["to_column"].should be_a Marten::DB::Management::Statement::Columns
        to_column_statement = statement.params["to_column"].as(Marten::DB::Management::Statement::Columns)
        to_column_statement.table.should eq TestUser.db_table
        to_column_statement.columns.should eq ["id"]
      end
    end

    describe "#ddl_rollbackable?" do
      it "returns false" do
        Marten::DB::Connection.default.schema_editor.ddl_rollbackable?.should be_false
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
  end
{% end %}
