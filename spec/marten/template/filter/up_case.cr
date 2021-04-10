require "./spec_helper"

describe Marten::Template::Filter::UpCase do
  describe "#apply" do
    it "returns the upcase version of the string representation of the initial value" do
      filter = Marten::Template::Filter::UpCase.new
      filter.apply(Marten::Template::Value.from("hello")).should eq "HELLO"
      filter.apply(Marten::Template::Value.from(42)).should eq "42"
    end
  end
end
