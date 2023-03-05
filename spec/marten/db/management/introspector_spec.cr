require "./spec_helper"

describe Marten::DB::Management::Introspector do
  describe "::for" do
    it "returns the expected introspector object for the passed connection" do
      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      for_mysql do
        introspector.should be_a Marten::DB::Management::Introspector::MySQL
      end

      for_postgresql do
        introspector.should be_a Marten::DB::Management::Introspector::PostgreSQL
      end

      for_sqlite do
        introspector.should be_a Marten::DB::Management::Introspector::SQLite
      end
    end
  end
end
