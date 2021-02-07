require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Exact do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::Exact.new(Post.get_field("title"), "foo", "table")
      predicate.to_sql(Marten::DB::Connection.default).should eq(
        {"table.title = %s", ["foo"]}
      )
    end
  end
end
