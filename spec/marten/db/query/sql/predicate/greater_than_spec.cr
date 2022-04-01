require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::GreaterThan do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::GreaterThan.new(Post.get_field("score"), 42, "table")
      predicate.to_sql(Marten::DB::Connection.default).should eq(
        {"table.score > %s", [42]}
      )
    end
  end
end
