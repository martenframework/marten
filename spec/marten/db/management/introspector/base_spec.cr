require "./spec_helper"

describe Marten::DB::Management::Introspector::Base do
  describe "#model_table_names" do
    it "returns the table names associated with models that are part of installed apps" do
      connection = Marten::DB::Connection.default
      introspector = connection.introspector

      introspector.model_table_names.should contain(TestUser.db_table)
    end
  end

  describe "#table_names" do
    it "returns the table names of the associated database connection" do
      connection = Marten::DB::Connection.default
      introspector = connection.introspector

      introspector.table_names.should contain(TestUser.db_table)
      introspector.table_names.should_not contain("unknown_table")
    end
  end
end
