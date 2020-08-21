require "./spec_helper"

describe Marten::Routing::Parameter::Slug do
  describe "#regex" do
    it "returns the string regex used to identify string parameters" do
      parameter = Marten::Routing::Parameter::Slug.new
      parameter.regex.should eq /[-a-zA-Z0-9_]+/
    end

    it "matches valid path slugs" do
      parameter = Marten::Routing::Parameter::Slug.new
      regex = Regex.new("^/path/#{parameter.regex.source}/test$")
      regex.match("/path/hello/test").should be_truthy
      regex.match("/path/this-is-a-string/test").should be_truthy
      regex.match("/path/-foo-bar-/test").should be_truthy
      regex.match("/path/foo_bar-test/test").should be_truthy
    end

    it "does not match invalid path slugs" do
      parameter = Marten::Routing::Parameter::Slug.new
      regex = Regex.new("^/path/#{parameter.regex.source}/test$")
      regex.match("/path/foo+bar/test").should be_falsey
      regex.match("/path/foo%bar/test").should be_falsey
    end
  end

  describe "#loads" do
    it "loads a string parameter" do
      parameter = Marten::Routing::Parameter::Slug.new
      parameter.loads("my-slug").should eq "my-slug"
    end
  end

  describe "#dumps" do
    it "dumps a string parameter" do
      parameter = Marten::Routing::Parameter::Slug.new
      parameter.dumps("my-slug").should eq "my-slug"
    end

    it "returns nil if the input is not a string" do
      parameter = Marten::Routing::Parameter::Slug.new
      parameter.dumps({foo: "bar"}).should be_nil
    end
  end
end
