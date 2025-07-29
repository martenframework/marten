require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Minute do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      field = TestUser.get_field("created_at")
      expr = Marten::DB::Query::SQL::Expression::Extract.new(field, "minute")
      predicate = Marten::DB::Query::SQL::Predicate::Exact.new(expr, 5, "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"MINUTE(table.created_at) = %s", [5]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(MINUTE FROM table.created_at) = %s", [5]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(strftime('%M', table.created_at) AS INTEGER) = %s", [5]}
        )
      end
    end

    it "returns the expected SQL statement with a different comparision predicate" do
      field = TestUser.get_field("created_at")
      expr = Marten::DB::Query::SQL::Expression::Extract.new(field, "minute")
      predicate = Marten::DB::Query::SQL::Predicate::GreaterThanOrEqual.new(expr, 5, "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"MINUTE(table.created_at) >= %s", [5]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(MINUTE FROM table.created_at) >= %s", [5]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(strftime('%M', table.created_at) AS INTEGER) >= %s", [5]}
        )
      end
    end
  end
end
