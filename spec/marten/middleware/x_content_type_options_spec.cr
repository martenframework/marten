require "./spec_helper"

describe Marten::Middleware::XContentTypeOptions do
  describe "#call" do
    it "inserts the X-Content-Type-Options header with the nosniff value" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::XContentTypeOptions.new
      response = middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.headers[:"X-Content-Type-Options"].should eq "nosniff"
    end

    it "returns the response early if it already contains the X-Content-Type-Options header" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::XContentTypeOptions.new
      response = middleware.call(
        request,
        -> {
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r[:"X-Content-Type-Options"] = "custom"
          r
        }
      )

      response.headers[:"X-Content-Type-Options"].should eq "custom"
    end

    it "does nothing if the response was exempted from using the X-Content-Type-Options header" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::XContentTypeOptions.new
      response = middleware.call(
        request,
        -> {
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r[:"X-Content-Type-Options-Exempt"] = "true"
          r
        }
      )

      response.headers.has_key?(:"X-Content-Type-Options").should be_false
      response.headers.has_key?(:"X-Content-Type-Options-Exempt").should be_false
    end
  end
end
