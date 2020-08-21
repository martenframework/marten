require "./spec_helper"

describe Marten::Routing::Parameter::String do
  describe "#regex" do
    it "returns the string regex used to identify string parameters" do
      parameter = Marten::Routing::Parameter::String.new
      parameter.regex.should eq /[^\/]+/
    end

    it "matches valid path strings" do
      parameter = Marten::Routing::Parameter::String.new
      parameter.regex.match("hello").should be_truthy
      parameter.regex.match("this-is-a-string").should be_truthy
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

    it "returns nil if the input is not a string" do
      parameter = Marten::Routing::Parameter::String.new
      parameter.dumps({foo: "bar"}).should be_nil
    end
  end
end
