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

    it "returns the expected value when the left operand is an annotation" do
      ann = Marten::DB::Query::SQL::Annotation::Count.new(
        field: Post.get_field("id"),
        alias_name: "post_count",
        distinct: false,
        alias_prefix: Post.db_table,
      )

      predicate = Marten::DB::Query::SQL::Predicate::In.new(
        ann,
        [1, 2, 3] of Marten::DB::Field::Any,
        "table"
      )

      predicate.to_sql(Marten::DB::Connection.default).should eq(
        {"#{ann.to_sql(with_alias: false)} IN ( %s , %s , %s )", [1, 2, 3]}
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
