require "./spec_helper"

describe Marten::Middleware::ReferrerPolicy do
  describe "#call" do
    it "returns the default Referrer-Policy header if not modified early" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::ReferrerPolicy.new
      response = middleware.call(
        request, ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.headers[:"Referrer-Policy"].should eq "same-origin"
    end

    it "returns the response early if it already contains the Referrer-Policy header" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::ReferrerPolicy.new
      response = middleware.call(
        request,
        ->{
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r[:"Referrer-Policy"] = "origin"
          r
        }
      )

      response.headers[:"Referrer-Policy"].should eq "origin"
    end

    it "inserts the right Referrer-Policy header value based on the related setting" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::ReferrerPolicy.new

      with_overridden_setting("referrer_policy", "origin") do
        response = middleware.call(
          request,
          ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
        )

        response.headers[:"Referrer-Policy"].should eq "origin"
      end
    end
  end
end
