require "./spec_helper"

describe Marten::Template::Filter::Capitalize do
  describe "#apply" do
    it "returns the capitalized version of the string representation of the initial value" do
      filter = Marten::Template::Filter::Capitalize.new
      filter.apply(Marten::Template::Value.from("hello")).should eq "Hello"
      filter.apply(Marten::Template::Value.from("FOOBAR")).should eq "Foobar"
      filter.apply(Marten::Template::Value.from(42)).should eq "42"
    end
  end
end
