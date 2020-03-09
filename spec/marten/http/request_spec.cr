require "./spec_helper"

describe Marten::HTTP::Request do
  describe "::new" do
    it "allows to initialize a quote by specifying a standard HTTP::Request object" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "")
      )
      request.nil?.should be_false
    end
  end

  describe "#method" do
    it "returns the request method" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "")
      )
      request.method.should eq "GET"
    end
  end
end
