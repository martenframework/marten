require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Day do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::Day.new(TestUser.get_field("created_at"), 5, "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"DAY(table.created_at) = %s", [5_i64]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(DAY FROM table.created_at) = %s", [5_i64]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%d', table.created_at) AS INTEGER) = %s", [5_i64]}
        )
      end
    end

    it "returns the expected SQL statement for an in comparison predicate" do
      predicate = Marten::DB::Query::SQL::Predicate::Day.new(
        TestUser.get_field("created_at"),
        ([Time.utc(2024, 1, 31), "5"] of Marten::DB::Field::Any),
        "table",
        comparison_predicate: "in",
      )

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"DAY(table.created_at) IN ( %s , %s )", [31_i64, 5_i64]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(DAY FROM table.created_at) IN ( %s , %s )", [31_i64, 5_i64]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%d', table.created_at) AS INTEGER) IN ( %s , %s )", [31_i64, 5_i64]}
        )
      end
    end

    it "returns the expected SQL statement for an isnull comparison predicate" do
      predicate = Marten::DB::Query::SQL::Predicate::Day.new(
        TestUser.get_field("created_at"),
        true,
        "table",
        comparison_predicate: "isnull",
      )

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"DAY(table.created_at) IS NULL", [] of ::DB::Any}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(DAY FROM table.created_at) IS NULL", [] of ::DB::Any}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%d', table.created_at) AS INTEGER) IS NULL", [] of ::DB::Any}
        )
      end
    end
  end
end
