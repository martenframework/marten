require "./spec_helper"

describe Marten::Middleware::XFrameOptions do
  describe "#call" do
    it "returns the response early if it already contains the X-Frame-Options header" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::XFrameOptions.new
      response = middleware.call(
        request,
        ->{
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r[:"X-Frame-Options"] = "SAMEORIGIN"
          r
        }
      )

      response.headers[:"X-Frame-Options"].should eq "SAMEORIGIN"
    end

    it "does nothing if the response was exempted from using the X-Frame-Options header" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::XFrameOptions.new
      response = middleware.call(
        request,
        ->{
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r[:"X-Frame-Options-Exempt"] = "true"
          r
        }
      )

      response.headers.has_key?(:"X-Frame-Options").should be_false
    end

    it "inserts the right X-Frame-Options header value based on the related setting" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      middleware = Marten::Middleware::XFrameOptions.new

      with_overridden_setting("x_frame_options", "DENY") do
        response = middleware.call(
          request,
          ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
        )

        response.headers[:"X-Frame-Options"].should eq "DENY"
      end

      with_overridden_setting("x_frame_options", "SAMEORIGIN") do
        response = middleware.call(
          request,
          ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
        )

        response.headers[:"X-Frame-Options"].should eq "SAMEORIGIN"
      end
    end
  end
end
