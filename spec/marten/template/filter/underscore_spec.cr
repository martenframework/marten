require "./spec_helper"

describe Marten::Template::Filter::Underscore do
  describe "#apply" do
    it "returns the underscored version of the string representation of the initial value" do
      filter = Marten::Template::Filter::Underscore.new
      filter.apply(Marten::Template::Value.from("FooBar")).should eq "foo_bar"
      filter.apply(Marten::Template::Value.from("fooBar")).should eq "foo_bar"
      filter.apply(Marten::Template::Value.from("foo_bar")).should eq "foo_bar"
    end
  end
end
