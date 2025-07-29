require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Year do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      field = TestUser.get_field("created_at")
      expr = Marten::DB::Query::SQL::Expression::Extract.new(field, "year")
      predicate = Marten::DB::Query::SQL::Predicate::Exact.new(expr, "2025", "table")

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
          {"CAST(strftime('%Y', table.created_at) AS INTEGER) = %s", ["2025"]}
        )
      end
    end

    it "returns the expected SQL statement with a different comparision predicate" do
      field = TestUser.get_field("created_at")
      expr = Marten::DB::Query::SQL::Expression::Extract.new(field, "year")
      predicate = Marten::DB::Query::SQL::Predicate::GreaterThanOrEqual.new(expr, 2025, "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"YEAR(table.created_at) >= %s", [2025]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(YEAR FROM table.created_at) >= %s", [2025]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(strftime('%Y', table.created_at) AS INTEGER) >= %s", [2025]}
        )
      end
    end
  end
end
