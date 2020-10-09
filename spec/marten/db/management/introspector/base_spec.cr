require "./spec_helper"

describe Marten::DB::Management::Introspector::Base do
  describe "#table_names" do
    it "returns the table names of the associated database connection" do
      connection = Marten::DB::Connection.default
      introspector = connection.introspector

      introspector.table_names.should contain(TestUser.db_table)
      introspector.table_names.should_not contain("unknown_table")
    end
  end
end
