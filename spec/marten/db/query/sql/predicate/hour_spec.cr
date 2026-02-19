require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Hour do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::Hour.new(TestUser.get_field("created_at"), 5, "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"HOUR(table.created_at) = %s", [5_i64]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(HOUR FROM table.created_at) = %s", [5_i64]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%H', table.created_at) AS INTEGER) = %s", [5_i64]}
        )
      end
    end

    it "raises if the field is not a date_time field" do
      predicate = Marten::DB::Query::SQL::Predicate::Hour.new(
        Post.get_field("title"),
        5,
        "table"
      )

      expect_raises(Marten::DB::Errors::InvalidField, "'hour' can only be used with date_time fields") do
        predicate.to_sql(Marten::DB::Connection.default)
      end
    end

    it "returns the expected SQL statement for an in comparison predicate" do
      predicate = Marten::DB::Query::SQL::Predicate::Hour.new(
        TestUser.get_field("created_at"),
        ([Time.utc(2024, 1, 1, 23, 0, 0), "5"] of Marten::DB::Field::Any),
        "table",
        comparison_predicate: "in",
      )

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"HOUR(table.created_at) IN ( %s , %s )", [23_i64, 5_i64]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(HOUR FROM table.created_at) IN ( %s , %s )", [23_i64, 5_i64]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%H', table.created_at) AS INTEGER) IN ( %s , %s )", [23_i64, 5_i64]}
        )
      end
    end

    it "returns the expected SQL statement for an isnull comparison predicate" do
      predicate = Marten::DB::Query::SQL::Predicate::Hour.new(
        TestUser.get_field("created_at"),
        false,
        "table",
        comparison_predicate: "isnull",
      )

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"HOUR(table.created_at) IS NOT NULL", [] of ::DB::Any}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(HOUR FROM table.created_at) IS NOT NULL", [] of ::DB::Any}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%H', table.created_at) AS INTEGER) IS NOT NULL", [] of ::DB::Any}
        )
      end
    end
  end
end
