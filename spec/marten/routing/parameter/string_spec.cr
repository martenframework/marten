require "./spec_helper"

describe Marten::Routing::Parameter::String do
  describe "#regex" do
    it "returns the string regex used to identify string parameters" do
      parameter = Marten::Routing::Parameter::String.new
      parameter.regex.should eq /[^\/]+/
    end
  end

  describe "#loads" do
    it "loads a string parameter" do
      parameter = Marten::Routing::Parameter::String.new
      parameter.loads("my-slug").should eq "my-slug"
    end
  end

  describe "#dumps" do
    it "dumps a string parameter" do
      parameter = Marten::Routing::Parameter::String.new
      parameter.dumps("my-slug").should eq "my-slug"
    end
  end
end
