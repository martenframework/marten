require "./spec_helper"

describe Marten::DB::Query::Expression::Filter do
  describe "#q" do
    it "provides a shortcut to generate query node in the context of a Q expression" do
      filter_expression = Marten::DB::Query::Expression::Filter.new
      filter_expression.q(foo: "bar", test: 42).should eq Marten::DB::Query::Node.new(foo: "bar", test: 42)
    end
  end
end
