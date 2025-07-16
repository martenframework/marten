require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Base do
  describe "::predicate_name" do
    it "allows to configure a predicate name and return its value" do
      Marten::DB::Query::SQL::Predicate::BaseSpec::Test.predicate_name.should eq "this_is_a_test"
    end
  end

  describe "#to_sql" do
    it "returns the expected value when the left operand is an annotation" do
      ann = Marten::DB::Query::SQL::Annotation::Count.new(
        field: Post.get_field("id"),
        alias_name: "post_count",
        distinct: false,
        alias_prefix: Post.db_table,
      )

      predicate = Marten::DB::Query::SQL::Predicate::Exact.new(ann, 42, "table")
      predicate.to_sql(Marten::DB::Connection.default).should eq(
        {"#{ann.to_sql(with_alias: false)} = %s", [42]}
      )
    end
  end
end

module Marten::DB::Query::SQL::Predicate::BaseSpec
  class Test < Marten::DB::Query::SQL::Predicate::Base
    predicate_name "this_is_a_test"
  end
end
