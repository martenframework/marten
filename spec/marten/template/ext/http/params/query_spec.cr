require "./spec_helper"

describe Marten::HTTP::Params::Query do
  describe "#resolve_template_attribute" do
    it "resolves a query value" do
      params = Marten::HTTP::Params::Query.new(
        Marten::HTTP::Params::Query::RawHash{"foo" => ["bar"], "xyz" => ["test1", "test2"]}
      )

      params.resolve_template_attribute("foo").should eq "bar"
    end
  end
end
