require "./spec_helper"

describe Marten::Middleware::SSLRedirect do
  around_each do |t|
    with_overridden_setting("allowed_hosts", ["example.com"]) do
      with_overridden_setting("use_x_forwarded_proto", true) do
        t.run
      end
    end
  end

  describe "#call" do
    it "redirects to HTTPS if the incoming request is not secure" do
      middleware = Marten::Middleware::SSLRedirect.new

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/foo/bar",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        ),
        ->{ Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200) }
      )

      response.should be_a Marten::HTTP::Response::MovedPermanently
      response.headers["Location"].should eq "https://example.com/foo/bar"
    end

    it "uses the custom host setting when redirecting to HTTPS if the incoming request is not secure" do
      middleware = Marten::Middleware::SSLRedirect.new

      with_overridden_setting("ssl_redirect.host", "custom-example.com", nilable: true) do
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/foo/bar",
              headers: HTTP::Headers{"Host" => "example.com"}
            )
          ),
          ->{ Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200) }
        )

        response.should be_a Marten::HTTP::Response::MovedPermanently
        response.headers["Location"].should eq "https://custom-example.com/foo/bar"
      end
    end

    it "does not redirect to HTTPS if the incoming request is secure" do
      middleware = Marten::Middleware::SSLRedirect.new

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
            headers: HTTP::Headers{
              "Host"              => "example.com",
              "X-Forwarded-Proto" => "https",
            }
          )
        ),
        ->{ Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200) }
      )

      response.status.should eq 200
      response.content.should eq "Regular response"
    end

    it "does not redirect to HTTPS if the incoming request path matches one of the exempted path strings" do
      middleware = Marten::Middleware::SSLRedirect.new

      with_overridden_setting("ssl_redirect.exempted_paths", ["/test/xyz", "/foo/bar"]) do
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/foo/bar",
              headers: HTTP::Headers{"Host" => "example.com"}
            )
          ),
          ->{ Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200) }
        )

        response.status.should eq 200
        response.content.should eq "Regular response"
      end
    end

    it "does not redirect to HTTPS if the incoming request path matches one of the exempted path regexes" do
      middleware = Marten::Middleware::SSLRedirect.new

      with_overridden_setting("ssl_redirect.exempted_paths", [/^\/no-ssl\/$/]) do
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/no-ssl/",
              headers: HTTP::Headers{"Host" => "example.com"}
            )
          ),
          ->{ Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200) }
        )

        response.status.should eq 200
        response.content.should eq "Regular response"
      end
    end
  end
end
