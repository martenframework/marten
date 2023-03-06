require "./spec_helper"

describe Marten::Template::Filter::Join do
  describe "#apply" do
    it "returns the string joined version of the array of values" do
      filter = Marten::Template::Filter::Join.new
      filter.apply(Marten::Template::Value.from(["Banana", "Orange", "Apple"]),
        Marten::Template::Value.from(", ")).should eq "Banana, Orange, Apple"
      filter.apply(Marten::Template::Value.from([42]),
        Marten::Template::Value.from(", ")).should eq "42"
      expect_raises(Marten::Template::Errors::UnsupportedType) do
        filter.apply(Marten::Template::Value.from(42),
          Marten::Template::Value.from(", "))
      end
    end
  end
end
