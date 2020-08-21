require "./spec_helper"

describe Marten::Routing::Parameter::Integer do
  describe "#regex" do
    it "returns the regex used to identify integer parameters" do
      parameter = Marten::Routing::Parameter::Integer.new
      parameter.regex.should eq /[0-9]+/
    end

    it "matches valid path integers" do
      parameter = Marten::Routing::Parameter::Integer.new
      parameter.regex.match("1").should be_truthy
      parameter.regex.match("42").should be_truthy
      parameter.regex.match("5670103402").should be_truthy
    end

    it "does not match invalid path integers" do
      parameter = Marten::Routing::Parameter::Integer.new
      parameter.regex.match("foo").should be_falsey
    end
  end

  describe "#loads" do
    it "loads an integer parameter" do
      parameter = Marten::Routing::Parameter::Integer.new
      parameter.loads("42").should eq 42
      parameter.loads("42").should be_a UInt64
    end
  end

  describe "#dumps" do
    it "dumps an integer parameter" do
      parameter = Marten::Routing::Parameter::Integer.new
      parameter.dumps(123_456).should eq "123456"
    end

    it "returns nil if the input is not an integer" do
      parameter = Marten::Routing::Parameter::Integer.new
      parameter.dumps({foo: "bar"}).should be_nil
    end

    it "returns nil if the integer is less than 0" do
      parameter = Marten::Routing::Parameter::Integer.new
      parameter.dumps(-42).should be_nil
    end
  end
end
