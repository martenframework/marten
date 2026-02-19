require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Year do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::Year.new(TestUser.get_field("created_at"), "2025", "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"YEAR(table.created_at) = %s", [2025_i64]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(YEAR FROM table.created_at) = %s", [2025_i64]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%Y', table.created_at) AS INTEGER) = %s", [2025_i64]}
        )
      end
    end

    it "returns the expected SQL statement with a comparison predicate" do
      predicate = Marten::DB::Query::SQL::Predicate::Year.new(
        TestUser.get_field("created_at"),
        2025,
        "table",
        comparison_predicate: "gte",
      )

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"YEAR(table.created_at) >= %s", [2025_i64]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(YEAR FROM table.created_at) >= %s", [2025_i64]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%Y', table.created_at) AS INTEGER) >= %s", [2025_i64]}
        )
      end
    end

    it "returns the expected SQL statement for an in comparison predicate" do
      predicate = Marten::DB::Query::SQL::Predicate::Year.new(
        TestUser.get_field("created_at"),
        ([Time.utc(2024, 1, 1), "2025"] of Marten::DB::Field::Any),
        "table",
        comparison_predicate: "in",
      )

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"YEAR(table.created_at) IN ( %s , %s )", [2024_i64, 2025_i64]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(YEAR FROM table.created_at) IN ( %s , %s )", [2024_i64, 2025_i64]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%Y', table.created_at) AS INTEGER) IN ( %s , %s )", [2024_i64, 2025_i64]}
        )
      end
    end

    it "returns the expected SQL statement for an isnull comparison predicate" do
      predicate = Marten::DB::Query::SQL::Predicate::Year.new(
        TestUser.get_field("created_at"),
        true,
        "table",
        comparison_predicate: "isnull",
      )

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"YEAR(table.created_at) IS NULL", [] of ::DB::Any}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"EXTRACT(YEAR FROM table.created_at) IS NULL", [] of ::DB::Any}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"CAST(STRFTIME('%Y', table.created_at) AS INTEGER) IS NULL", [] of ::DB::Any}
        )
      end
    end

    it "raises if the isnull comparison predicate does not receive a boolean" do
      predicate = Marten::DB::Query::SQL::Predicate::Year.new(
        TestUser.get_field("created_at"),
        "false",
        "table",
        comparison_predicate: "isnull",
      )

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "'year__isnull' expects a boolean") do
        predicate.to_sql(Marten::DB::Connection.default)
      end
    end
  end
end
