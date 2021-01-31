require "./spec_helper"

describe Marten::DB::Query::SQL::Predicate::Base do
  describe "::predicate_name" do
    it "allows to configure a predicate name and return its value" do
      Marten::DB::Query::SQL::Predicate::BaseSpec::Test.predicate_name.should eq "this_is_a_test"
    end
  end
end

module Marten::DB::Query::SQL::Predicate::BaseSpec
  class Test < Marten::DB::Query::SQL::Predicate::Base
    predicate_name "this_is_a_test"
  end
end
