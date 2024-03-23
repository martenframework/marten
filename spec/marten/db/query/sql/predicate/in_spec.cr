require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::In do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::In.new(
        Post.get_field("title"),
        ["foo", "bar"] of Marten::DB::Field::Any,
        "table"
      )
      predicate.to_sql(Marten::DB::Connection.default).should eq(
        {"table.title IN ( %s , %s )", ["foo", "bar"]}
      )
    end

    it "raises if the right operand is not an array" do
      predicate = Marten::DB::Query::SQL::Predicate::In.new(
        Post.get_field("title"),
        42,
        "table"
      )

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "In predicate requires an array of values") do
        predicate.to_sql(Marten::DB::Connection.default)
      end
    end

    it "raises if the specified array is empty" do
      predicate = Marten::DB::Query::SQL::Predicate::In.new(
        Post.get_field("title"),
        [] of Marten::DB::Field::Any,
        "table"
      )

      expect_raises(Marten::DB::Errors::EmptyResults) do
        predicate.to_sql(Marten::DB::Connection.default)
      end
    end
  end
end
