require "./spec_helper"

describe Marten::Template::Filter::LineBreaks do
  describe "#apply" do
    it "returns the version of the string representation of the initial value with newlines replaced by HTML <br />" do
      filter = Marten::Template::Filter::LineBreaks.new
      filter.apply(Marten::Template::Value.from("\n")).should eq "<br />"
      filter.apply(Marten::Template::Value.from("\nFOOBAR")).should eq "<br />FOOBAR"
      filter.apply(Marten::Template::Value.from("New Year\n")).should eq "New Year<br />"
      filter.apply(Marten::Template::Value.from("\nFTX\n")).should eq "<br />FTX<br />"
      filter.apply(Marten::Template::Value.from("\nHello\nMarten\n")).should eq "<br />Hello<br />Marten<br />"
    end
  end
end
