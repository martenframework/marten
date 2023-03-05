require "./spec_helper"

describe Marten::DB::Management::Introspector::Base do
  describe "#model_table_names" do
    it "returns the table names associated with models that are part of installed apps" do
      connection = Marten::DB::Connection.default
      introspector = Marten::DB::Management::Introspector.for(connection)

      introspector.model_table_names.should contain(TestUser.db_table)
    end
  end
end
