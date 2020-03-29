require "./spec_helper"

describe Marten::HTTP::Request do
  describe "::new" do
    it "allows to initialize a request by specifying a standard HTTP::Request object" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "")
      )
      request.nil?.should be_false
    end
  end

  describe "#body" do
    it "returns the request body" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "/test/xyz", body: "foo=bar")
      )
      request.body.should eq "foo=bar"
    end

    it "returns an empty string if the request has no body" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "/test/xyz")
      )
      request.body.should eq ""
    end
  end

  describe "#full_path" do
    it "returns the request full path when query params are present" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "/test/xyz?foo=bar&xyz=test&foo=baz")
      )
      request.full_path.should eq "/test/xyz?foo=bar&foo=baz&xyz=test"
    end

    it "returns the request full path when query params are not present" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "/test/xyz")
      )
      request.full_path.should eq "/test/xyz"
    end
  end

  describe "#headers" do
    it "returns the request headers" do
      headers = ::HTTP::Headers{"Content-Type" => "application/json"}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "/test/xyz", headers: headers)
      )
      request.headers.should be_a Marten::HTTP::Headers
      request.headers.size.should eq 1
      request.headers["Content-Type"].should eq "application/json"
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

  describe "#path" do
    it "returns the request path" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "/test/xyz")
      )
      request.path.should eq "/test/xyz"
    end
  end

  describe "#query_params" do
    it "returns the request query parameters" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "/test/xyz?foo=bar&xyz=test&foo=baz")
      )
      request.query_params.should be_a Marten::HTTP::QueryParams
      request.query_params.size.should eq 3
      request.query_params.fetch_all(:foo).should eq ["bar", "baz"]
      request.query_params.fetch_all(:xyz).should eq ["test"]
    end
  end
end
