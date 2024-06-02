require "./spec_helper"

describe Marten::DB::Query::Expression::Filter do
  describe "#q" do
    it "provides a shortcut to generate query node in the context of a Q expression" do
      filter_expression = Marten::DB::Query::Expression::Filter.new
      filter_expression.q(foo: "bar", test: 42).should eq Marten::DB::Query::Node.new(foo: "bar", test: 42)
    end

    it "provides a shortcut to generate raw query node in the context of a Q expression" do
      filter_expression = Marten::DB::Query::Expression::Filter.new

      raw_params = {} of String => ::DB::Any
      raw_params["foo"] = "bar"

      filter_expression.q("foo = :foo", foo: "bar").should eq Marten::DB::Query::RawNode.new("foo = :foo", raw_params)
    end
  end
end
