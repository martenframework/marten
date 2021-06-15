require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
  describe Marten::DB::Management::Introspector::MySQL do
    describe "#get_foreign_key_constraint_names_statement" do
      it "returns the expected SQL allowing to list foreign key constraints" do
        introspector = Marten::DB::Connection.default.introspector
        introspector.get_foreign_key_constraint_names_statement("test_table", "test_column").should eq(
          "SELECT c.constraint_name " \
          "FROM information_schema.key_column_usage AS c " \
          "WHERE c.table_schema = DATABASE() AND c.table_name = 'test_table' " \
          "AND c.column_name = 'test_column' " \
          "AND c.referenced_column_name IS NOT NULL"
        )
      end
    end

    describe "#list_table_names_statement" do
      it "returns the expected statement" do
        introspector = Marten::DB::Connection.default.introspector
        introspector.list_table_names_statement.should eq "SHOW TABLES"
      end
    end
  end
{% end %}
