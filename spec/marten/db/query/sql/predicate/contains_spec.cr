require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Contains do
  describe "#to_sql" do
    it "returns the expected SQL statement" do
      predicate = Marten::DB::Query::SQL::Predicate::Contains.new(Post.get_field("title"), "foo", "table")

      for_mysql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"table.title LIKE BINARY %s", ["%foo%"]}
        )
      end

      for_postgresql do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"table.title LIKE %s", ["%foo%"]}
        )
      end

      for_sqlite do
        predicate.to_sql(Marten::DB::Connection.default).should eq(
          {"table.title LIKE %s ESCAPE '\\'", ["%foo%"]}
        )
      end
    end
  end
end
