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
  end
end
