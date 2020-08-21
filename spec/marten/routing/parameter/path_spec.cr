require "./spec_helper"

describe Marten::Routing::Parameter::Path do
  describe "#regex" do
    it "returns the string regex used to identify path parameters" do
      parameter = Marten::Routing::Parameter::Path.new
      parameter.regex.should eq /.+/
    end

    it "matches valid paths" do
      parameter = Marten::Routing::Parameter::Path.new
      regex = Regex.new("^/test/#{parameter.regex.source}$")
      regex.match("/test/hello/test").should be_truthy
      regex.match("/test/foo/bar").should be_truthy
      regex.match("/test/foobar").should be_truthy
    end

    it "does not match empty paths" do
      parameter = Marten::Routing::Parameter::Path.new
      regex = Regex.new("^/test/#{parameter.regex.source}$")
      regex.match("/test/").should be_falsey
    end
  end

  describe "#loads" do
    it "loads a string parameter" do
      parameter = Marten::Routing::Parameter::Path.new
      parameter.loads("foo/bar").should eq "foo/bar"
    end
  end

  describe "#dumps" do
    it "dumps a string parameter" do
      parameter = Marten::Routing::Parameter::Path.new
      parameter.dumps("foo/bar").should eq "foo/bar"
    end

    it "returns nil if the input is not a string" do
      parameter = Marten::Routing::Parameter::Path.new
      parameter.dumps({foo: "bar"}).should be_nil
    end
  end
end
