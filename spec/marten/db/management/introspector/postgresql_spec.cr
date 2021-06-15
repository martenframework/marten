require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
  describe Marten::DB::Management::Introspector::PostgreSQL do
    describe "#get_foreign_key_constraint_names_statement" do
      it "returns the expected SQL allowing to list foreign key constraints" do
        introspector = Marten::DB::Connection.default.introspector
        introspector.get_foreign_key_constraint_names_statement("test_table", "test_column").should eq(
          "SELECT c.conname " \
          "FROM pg_constraint AS c " \
          "JOIN pg_class AS cl ON c.conrelid = cl.oid " \
          "WHERE cl.relname = 'test_table' " \
          "AND pg_catalog.pg_table_is_visible(cl.oid) AND c.contype = 'f' " \
          "AND 'test_column'=ANY(array( " \
          "  SELECT attname " \
          "  FROM unnest(c.conkey) WITH ORDINALITY cols(colid, arridx) " \
          "  JOIN pg_attribute AS ca ON cols.colid = ca.attnum " \
          "  WHERE ca.attrelid = c.conrelid " \
          "  ORDER BY cols.arridx " \
          "))"
        )
      end
    end

    describe "#list_table_names_statement" do
      it "returns the expected statement" do
        introspector = Marten::DB::Connection.default.introspector
        introspector.list_table_names_statement.should eq(
          "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
        )
      end
    end
  end
{% end %}
