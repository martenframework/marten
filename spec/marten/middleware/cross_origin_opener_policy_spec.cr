require "./spec_helper"

describe Marten::Middleware::CrossOriginOpenerPolicy do
  describe "#call" do
    it "inserts the Cross-Origin-Opener-Policy header with the default value" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::CrossOriginOpenerPolicy.new
      response = middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.headers[:"Cross-Origin-Opener-Policy"].should eq "same-origin"
    end

    it "returns the response early if it already contains the Cross-Origin-Opener-Policy header" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::CrossOriginOpenerPolicy.new
      response = middleware.call(
        request,
        -> {
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r[:"Cross-Origin-Opener-Policy"] = "unsafe-none"
          r
        }
      )

      response.headers[:"Cross-Origin-Opener-Policy"].should eq "unsafe-none"
    end

    it "does nothing if the response was exempted from using the Cross-Origin-Opener-Policy header" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::CrossOriginOpenerPolicy.new
      response = middleware.call(
        request,
        -> {
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r[:"Cross-Origin-Opener-Policy-Exempt"] = "true"
          r
        }
      )

      response.headers.has_key?(:"Cross-Origin-Opener-Policy").should be_false
      response.headers.has_key?(:"Cross-Origin-Opener-Policy-Exempt").should be_false
    end

    it "inserts the right Cross-Origin-Opener-Policy header value based on the related setting" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::CrossOriginOpenerPolicy.new

      with_overridden_setting("cross_origin_opener_policy", "same-origin-allow-popups") do
        response = middleware.call(
          request,
          -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
        )

        response.headers[:"Cross-Origin-Opener-Policy"].should eq "same-origin-allow-popups"
      end
    end
  end
end
