require "./spec_helper"

describe Marten::Template::Filter::Split do
  describe "#apply" do
    it "returns the split array representation of the string" do
      filter = Marten::Template::Filter::Split.new
      filter.apply(Marten::Template::Value.from("Banana,Orange,Apple"),
        Marten::Template::Value.from(",")).should eq ["Banana", "Orange", "Apple"]
      filter.apply(Marten::Template::Value.from("Banana"),
        Marten::Template::Value.from(",")).should eq ["Banana"]
      filter.apply(Marten::Template::Value.from(42),
        Marten::Template::Value.from(",")).should eq ["42"]
    end
  end
end
