require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Month do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::Month.new(TestUser.get_field("created_at"), "5", "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"MONTH(table.created_at) = %s", ["05"]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(MONTH FROM table.created_at) = %s", ["05"]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"strftime('%m', table.created_at) = %s", ["05"]}
        )
      end
    end
  end
end
