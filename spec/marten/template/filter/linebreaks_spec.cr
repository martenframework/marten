require "./spec_helper"

describe Marten::Template::Filter::LineBreaks do
  describe "#apply" do
    it "returns the capitalized version of the string representation of the initial value" do
      filter = Marten::Template::Filter::LineBreaks.new
      filter.apply(Marten::Template::Value.from("\n")).should eq "<br />"
      filter.apply(Marten::Template::Value.from("\nFOOBAR")).should eq "<br />FOOBAR"
      filter.apply(Marten::Template::Value.from("New Year\n")).should eq "New Year<br />"
      filter.apply(Marten::Template::Value.from("\nFTX\n")).should eq "<br />FTX<br />"
      filter.apply(Marten::Template::Value.from("\nHello\nMarten\n")).should eq "<br />Hello<br />Marten<br />"
    end
  end
end
