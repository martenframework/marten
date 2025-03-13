require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Year do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::Year.new(TestUser.get_field("created_at"), "2025", "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"YEAR(table.created_at) = %s", ["2025"]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(YEAR FROM table.created_at) = %s", ["2025"]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"strftime('%Y', table.created_at) = %s", ["2025"]}
        )
      end
    end
  end
end
