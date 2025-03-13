require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Minute do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::Minute.new(TestUser.get_field("created_at"), "5", "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"MINUTE(table.created_at) = %s", ["05"]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(MINUTE FROM table.created_at) = %s", ["05"]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"strftime('%M', table.created_at) = %s", ["05"]}
        )
      end
    end
  end
end
