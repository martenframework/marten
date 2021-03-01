require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::IsNull do
  describe "#to_sql" do
    it "returns the expected SQL statement for truthy values" do
      predicate = Marten::DB::Query::SQL::Predicate::IsNull.new(
        Post.get_field("published"),
        true,
        "table"
      )
      predicate.to_sql(Marten::DB::Connection.default).should eq(
        {"table.published IS NULL", [] of String}
      )
    end

    it "returns the expected SQL statement for falsy values" do
      predicate = Marten::DB::Query::SQL::Predicate::IsNull.new(
        Post.get_field("published"),
        false,
        "table"
      )
      predicate.to_sql(Marten::DB::Connection.default).should eq(
        {"table.published IS NOT NULL", [] of String}
      )
    end
  end
end
