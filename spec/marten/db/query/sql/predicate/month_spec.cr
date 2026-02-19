require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Month do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::Month.new(TestUser.get_field("created_at"), 5, "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"MONTH(table.created_at) = %s", [5_i64]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(MONTH FROM table.created_at) = %s", [5_i64]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%m', table.created_at) AS INTEGER) = %s", [5_i64]}
        )
      end
    end

    it "raises if the value is outside the expected range" do
      predicate = Marten::DB::Query::SQL::Predicate::Month.new(TestUser.get_field("created_at"), 13, "table")

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "'month' expects an integer between 1 and 12") do
        predicate.to_sql(Marten::DB::Connection.default)
      end
    end

    it "returns the expected SQL statement for an in comparison predicate" do
      predicate = Marten::DB::Query::SQL::Predicate::Month.new(
        TestUser.get_field("created_at"),
        ([Time.utc(2024, 12, 1), "5"] of Marten::DB::Field::Any),
        "table",
        comparison_predicate: "in",
      )

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"MONTH(table.created_at) IN ( %s , %s )", [12_i64, 5_i64]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(MONTH FROM table.created_at) IN ( %s , %s )", [12_i64, 5_i64]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%m', table.created_at) AS INTEGER) IN ( %s , %s )", [12_i64, 5_i64]}
        )
      end
    end

    it "returns the expected SQL statement for an isnull comparison predicate" do
      predicate = Marten::DB::Query::SQL::Predicate::Month.new(
        TestUser.get_field("created_at"),
        false,
        "table",
        comparison_predicate: "isnull",
      )

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"MONTH(table.created_at) IS NOT NULL", [] of ::DB::Any}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(MONTH FROM table.created_at) IS NOT NULL", [] of ::DB::Any}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%m', table.created_at) AS INTEGER) IS NOT NULL", [] of ::DB::Any}
        )
      end
    end

    it "raises if one of the in values is outside the expected range" do
      predicate = Marten::DB::Query::SQL::Predicate::Month.new(
        TestUser.get_field("created_at"),
        [1, 13] of Marten::DB::Field::Any,
        "table",
        comparison_predicate: "in",
      )

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "'month' expects an integer between 1 and 12") do
        predicate.to_sql(Marten::DB::Connection.default)
      end
    end
  end
end
