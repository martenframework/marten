require "./spec_helper"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "sqlite" || !env("MARTEN_SPEC_DB_CONNECTION") %}
  describe Marten::DB::Management::Introspector::SQLite do
    describe "foreign_key_constraint_names" do
      it "returns an empty array" do
        introspector = Marten::DB::Connection.default.introspector
        introspector.foreign_key_constraint_names("test_table", "test_column").should be_empty
      end
    end

    describe "#get_foreign_key_constraint_names_statement" do
      it "raises NotImplementedError" do
        introspector = Marten::DB::Connection.default.introspector
        expect_raises(NotImplementedError) do
          introspector.get_foreign_key_constraint_names_statement("test_table", "test_column")
        end
      end
    end

    describe "#list_table_names_statement" do
      it "returns the expected statement" do
        introspector = Marten::DB::Connection.default.introspector
        introspector.list_table_names_statement.should eq(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
        )
      end
    end
  end
{% end %}
