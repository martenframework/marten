require "./spec_helper"

describe Marten::Template::Filter::DownCase do
  describe "#apply" do
    it "returns the downcase version of the string representation of the initial value" do
      filter = Marten::Template::Filter::DownCase.new
      filter.apply(Marten::Template::Value.from("Hello")).should eq "hello"
      filter.apply(Marten::Template::Value.from("FOO BAR")).should eq "foo bar"
      filter.apply(Marten::Template::Value.from(42)).should eq "42"
    end
  end
end
