require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
  describe Marten::DB::Management::SchemaEditor::MySQL do
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
  end
{% end %}
