require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate do
  describe "::register" do
    it "allows to register a new predicate implementation" do
      Marten::DB::Query::SQL::Predicate.register(Marten::DB::Query::SQL::PredicateSpec::TestPredicate)
      Marten::DB::Query::SQL::Predicate.registry["predicate_test"].should eq(
        Marten::DB::Query::SQL::PredicateSpec::TestPredicate
      )
    end
  end

  describe "::registry" do
    it "returns the registered predicate implementations" do
      Marten::DB::Query::SQL::Predicate.registry["contains"].should eq(Marten::DB::Query::SQL::Predicate::Contains)
      Marten::DB::Query::SQL::Predicate.registry["exact"].should eq(Marten::DB::Query::SQL::Predicate::Exact)
    end
  end
end

module Marten::DB::Query::SQL::PredicateSpec
  class TestPredicate < Marten::DB::Query::SQL::Predicate::Base
    predicate_name "predicate_test"
  end
end
