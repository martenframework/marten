require "./spec_helper"

describe Marten::Middleware::ContentSecurityPolicy do
  describe "#call" do
    it "returns the response unmodified if the status code is 304" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )

      middleware = Marten::Middleware::ContentSecurityPolicy.new
      response = middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 304) }
      )

      response.status.should eq 304
      response.headers["Content-Security-Policy"]?.should be_nil
      response.headers["Content-Security-Policy-Report-Only"]?.should be_nil
    end

    it "returns the response unmodified if it already contains a Content-Security-Policy header value" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"                    => "example.com",
          "Content-Security-Policy" => "default-src 'self' example.com *.example.com",
        },
      )

      middleware = Marten::Middleware::ContentSecurityPolicy.new
      response = middleware.call(
        request,
        ->{
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r.headers["Content-Security-Policy"] = "default-src 'self' example.com *.example.com"
          r
        }
      )

      response.status.should eq 200
      response.headers["Content-Security-Policy"].should eq "default-src 'self' example.com *.example.com"
    end

    it "returns the response unmodified if it already contains a Content-Security-Policy-Report-Only header value" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"                    => "example.com",
          "Content-Security-Policy" => "default-src 'self' example.com *.example.com",
        },
      )

      middleware = Marten::Middleware::ContentSecurityPolicy.new
      response = middleware.call(
        request,
        ->{
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r.headers["Content-Security-Policy-Report-Only"] = "default-src 'self' example.com *.example.com"
          r
        }
      )

      response.status.should eq 200
      response.headers["Content-Security-Policy"]?.should be_nil
      response.headers["Content-Security-Policy-Report-Only"].should eq "default-src 'self' example.com *.example.com"
    end

    it "returns the response unmodified if the response was exempted from having the Content-Security-Policy header" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"                    => "example.com",
          "Content-Security-Policy" => "default-src 'self' example.com *.example.com",
        },
      )

      middleware = Marten::Middleware::ContentSecurityPolicy.new
      response = middleware.call(
        request,
        ->{
          r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          r.headers["Content-Security-Policy-Exempt"] = "true"
          r
        }
      )

      response.status.should eq 200
      response.headers["Content-Security-Policy"]?.should be_nil
      response.headers["Content-Security-Policy-Report-Only"]?.should be_nil
      response.headers["Content-Security-Policy-Exempt"]?.should be_nil
    end

    it "inserts the Content-Security-Policy value configured in the settings by default" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )

      middleware = Marten::Middleware::ContentSecurityPolicy.new
      response = middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.status.should eq 200
      response.headers["Content-Security-Policy"].should eq Marten.settings.content_security_policy.default_policy.build
      response.headers["Content-Security-Policy-Report-Only"]?.should be_nil
    end

    it "sets the expected header if the report only mode is enabled" do
      with_overridden_setting("content_security_policy.report_only", true) do
        request = Marten::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )

        middleware = Marten::Middleware::ContentSecurityPolicy.new
        response = middleware.call(
          request,
          ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
        )

        response.status.should eq 200
        response.headers["Content-Security-Policy-Report-Only"].should eq(
          Marten.settings.content_security_policy.default_policy.build
        )
        response.headers["Content-Security-Policy"]?.should be_nil
      end
    end

    it "uses the Content-Security-Policy value from the request if it is set" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.content_security_policy = Marten::HTTP::ContentSecurityPolicy.new do |csp|
        csp.default_src = :self
        csp.font_src = [:self, "example.com"]
        csp.block_all_mixed_content = true
      end

      middleware = Marten::Middleware::ContentSecurityPolicy.new
      response = middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.status.should eq 200
      response.headers["Content-Security-Policy"].should eq request.content_security_policy.try(&.build)
      response.headers["Content-Security-Policy-Report-Only"]?.should be_nil
    end

    it "makes use of the configured nonce directives when generating the Content-Security-Policy value" do
      with_overridden_setting(
        "content_security_policy.nonce_directives",
        ["script-src", "style-src"],
        nilable: true
      ) do
        request = Marten::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
        request.content_security_policy = Marten::HTTP::ContentSecurityPolicy.new do |csp|
          csp.font_src = [:self, "example.com"]
          csp.script_src = :self
        end
        nonce = request.content_security_policy_nonce

        middleware = Marten::Middleware::ContentSecurityPolicy.new
        response = middleware.call(
          request,
          ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
        )

        response.status.should eq 200
        response.headers["Content-Security-Policy"].should eq(
          "font-src 'self' example.com; script-src 'self' 'nonce-#{nonce}'"
        )
        response.headers["Content-Security-Policy-Report-Only"]?.should be_nil
      end
    end
  end
end
