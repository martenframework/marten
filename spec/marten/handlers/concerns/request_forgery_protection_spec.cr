require "./spec_helper"

describe Marten::Handlers::RequestForgeryProtection do
  around_each do |t|
    original_allowed_hosts = Marten.settings.allowed_hosts
    original_csrf_cookie_domain = Marten.settings.csrf.cookie_domain
    original_csrf_protection_enabled = Marten.settings.csrf.protection_enabled
    original_use_x_forwarded_proto = Marten.settings.use_x_forwarded_proto

    t.run

    Marten.settings.allowed_hosts = original_allowed_hosts
    Marten.settings.csrf.cookie_domain = original_csrf_cookie_domain
    Marten.settings.csrf.protection_enabled = original_csrf_protection_enabled
    Marten.settings.use_x_forwarded_proto = original_use_x_forwarded_proto
  end

  describe "::protect_from_forgery" do
    it "can enable CSRF protection" do
      Marten::Handlers::RequestForgeryProtectionSpec::TestHandlerWithProtectionEnabled.protect_from_forgery?.should(
        be_true
      )
    end

    it "can disable CSRF protection" do
      Marten::Handlers::RequestForgeryProtectionSpec::TestHandlerWithProtectionDisabled.protect_from_forgery?.should(
        be_false
      )
    end
  end

  describe "::protect_from_forgery?" do
    it "returns true if CSRF protection is enabled globally" do
      Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.protect_from_forgery?.should be_true
    end

    it "returns false if CSRF protection is disabled globally" do
      Marten.settings.csrf.protection_enabled = false
      Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.protect_from_forgery?.should be_false
    end

    it "returns true if CSRF protection is enabled locally" do
      Marten::Handlers::RequestForgeryProtectionSpec::TestHandlerWithProtectionEnabled.protect_from_forgery?.should(
        be_true
      )
    end

    it "returns false if CSRF protection is disabled locally" do
      Marten::Handlers::RequestForgeryProtectionSpec::TestHandlerWithProtectionDisabled.protect_from_forgery?.should(
        be_false
      )
    end
  end

  describe "#process_dispatch" do
    %w(GET HEAD OPTIONS TRACE).each do |safe_method|
      it "allows #{safe_method} requests" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: safe_method,
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
        response = handler.process_dispatch

        response.content.should eq "OK_#{safe_method}"
        response.status.should eq 200
      end

      it "does not set the CSRF token cookie on #{safe_method} requests if the CSRF token is not used" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: safe_method,
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
        response = handler.process_dispatch

        response.cookies["csrftoken"]?.should be_nil
      end
    end

    %w(DELETE PATCH POST PUT).each do |unsafe_method|
      it "allows #{unsafe_method} requests if the X-CSRF-Token header is specified and matches the CSRF token cookie" do
        token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

        raw_request = ::HTTP::Request.new(
          method: unsafe_method,
          resource: "/test/xyz",
          headers: HTTP::Headers{
            "Host"         => "example.com",
            "Content-Type" => "application/x-www-form-urlencoded",
            "X-CSRF-Token" => token,
          },
          body: "foo=bar"
        )
        raw_request.cookies["csrftoken"] = token
        request = Marten::HTTP::Request.new(raw_request)

        handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
        response = handler.process_dispatch

        response.content.should eq "OK_#{unsafe_method}"
        response.status.should eq 200
      end
    end

    it "allows unsafe requests if CSRF protection is disabled and requests does not contain the CSRF token" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandlerWithProtectionDisabled.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK"
      response.status.should eq 200
    end

    it "allows unsafe requests if CSRF protection was disabled at the request level for test purposes" do
      request = Marten::Handlers::RequestForgeryProtectionSpec::TestRequest.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.test_disable_request_forgery_protection = true

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "regenerates the CSRF token if the persisted one is invalid and sets the corresponding cookie" do
      raw_request = ::HTTP::Request.new(method: "GET", resource: "/test/xyz")
      raw_request.cookies["csrftoken"] = "bad"
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      csrf_token = handler._csrf_token
      csrf_token.should_not be_nil
      csrf_token.should_not eq "bad"
      response.cookies["csrftoken"].should eq csrf_token
    end

    it "allows unsafe requests if the csrftoken POST parameter is specified and matches the CSRF token cookie" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "allows unsafe requests if the X-CSRF-Token header is specified and matches the CSRF token cookie" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Content-Type" => "application/x-www-form-urlencoded",
          "X-CSRF-Token" => token,
        },
        body: "foo=bar"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "does not return a 403 if the origin corresponds to an allowed host" do
      Marten.settings.allowed_hosts = ["example.com"]

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Origin"       => "http://example.com",
          "Content-Type" => "application/x-www-form-urlencoded",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "does not return a 403 if the origin corresponds exactly to a CSRF trusted origin" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.csrf.trusted_origins = ["http://sub.other.com"]

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Origin"       => "http://sub.other.com",
          "Content-Type" => "application/x-www-form-urlencoded",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "does not return a 403 if the origin corresponds to a CSRF trusted origin pattern" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.csrf.trusted_origins = ["http://*.other.com"]

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Origin"       => "http://sub42.other.com",
          "Content-Type" => "application/x-www-form-urlencoded",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "returns a 403 if the origin does not correspond to a CSRF trusted origin" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.csrf.trusted_origins = ["https://*.example.com"]

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Origin"       => "https://evil.com",
          "Content-Type" => "application/x-www-form-urlencoded",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Origin 'https://evil.com' is not trusted"
      response.status.should eq 403
    end

    it "returns a 403 if the origin cannot be parsed properly" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.csrf.trusted_origins = ["https://*.example.com"]

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Origin"       => "this is bad",
          "Content-Type" => "application/x-www-form-urlencoded",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Origin 'this is bad' is not trusted"
      response.status.should eq 403
    end

    it "returns a 403 if the origin does not correspond to an allowed host" do
      Marten.settings.allowed_hosts = ["example.com"]

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Origin"       => "http://unknown.com",
          "Content-Type" => "application/x-www-form-urlencoded",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Origin 'http://unknown.com' is not trusted"
      response.status.should eq 403
    end

    it "returns a 403 if the host header does not correspond and the origin header is set" do
      Marten.settings.allowed_hosts = ["example.com"]

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "unknown.com",
          "Origin"       => "http://unknown.com",
          "Content-Type" => "application/x-www-form-urlencoded",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Origin 'http://unknown.com' is not trusted"
      response.status.should eq 403
    end

    it "returns a 403 for secure requests if nor the referer nor the origin headers are set" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.use_x_forwarded_proto = true

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"              => "example.com",
          "Content-Type"      => "application/x-www-form-urlencoded",
          "X-Forwarded-Proto" => "https",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Referer is missing"
      response.status.should eq 403
    end

    it "does not return a 403 for secure requests if the referer is one of the trusted origins" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.csrf.trusted_origins = ["https://sub.example.com"]
      Marten.settings.use_x_forwarded_proto = true

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"              => "example.com",
          "Referer"           => "https://sub.example.com/path/to/thing",
          "Content-Type"      => "application/x-www-form-urlencoded",
          "X-Forwarded-Proto" => "https",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "does not return a 403 for secure requests if the referer matches the configured CSRF cookie domain" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.csrf.cookie_domain = ".other.com"
      Marten.settings.use_x_forwarded_proto = true

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"              => "example.com",
          "Referer"           => "https://sub.other.com/path/to/thing",
          "Content-Type"      => "application/x-www-form-urlencoded",
          "X-Forwarded-Proto" => "https",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "does not return a 403 for secure requests if the referer matches the CSRF cookie domain with a port" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.csrf.cookie_domain = ".other.com"
      Marten.settings.use_x_forwarded_proto = true

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"              => "example.com:8080",
          "Referer"           => "https://sub.other.com:8080/path/to/thing",
          "Content-Type"      => "application/x-www-form-urlencoded",
          "X-Forwarded-Proto" => "https",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "does not return a 403 for secure requests if the referer matches the request host" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.use_x_forwarded_proto = true

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"              => "example.com",
          "Referer"           => "https://example.com/path/to/thing",
          "Content-Type"      => "application/x-www-form-urlencoded",
          "X-Forwarded-Proto" => "https",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "does not return a 403 for secure requests if the referer matches the request host with a port" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.use_x_forwarded_proto = true

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"              => "example.com:8080",
          "Referer"           => "https://example.com:8080/path/to/thing",
          "Content-Type"      => "application/x-www-form-urlencoded",
          "X-Forwarded-Proto" => "https",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "OK_POST"
      response.status.should eq 200
    end

    it "returns a 403 for secure requests if the referer does not have the https scheme" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.use_x_forwarded_proto = true

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"              => "example.com",
          "Referer"           => "http://example.com",
          "Content-Type"      => "application/x-www-form-urlencoded",
          "X-Forwarded-Proto" => "https",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Referer 'http://example.com' is not trusted"
      response.status.should eq 403
    end

    it "returns a 403 for secure requests if the referer is correct but the host is invalid" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.use_x_forwarded_proto = true

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"              => "unknown.com",
          "Referer"           => "https://example.com",
          "Content-Type"      => "application/x-www-form-urlencoded",
          "X-Forwarded-Proto" => "https",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Referer 'https://example.com' is not trusted"
      response.status.should eq 403
    end

    it "returns a 403 for secure requests if the referer is not a valid URI" do
      Marten.settings.allowed_hosts = ["example.com"]
      Marten.settings.use_x_forwarded_proto = true

      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"              => "example.com",
          "Referer"           => "this is bad",
          "Content-Type"      => "application/x-www-form-urlencoded",
          "X-Forwarded-Proto" => "https",
        },
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Referer 'this is bad' is not trusted"
      response.status.should eq 403
    end

    it "returns a 403 if the no CSRF token was previously set" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Content-Type" => "application/x-www-form-urlencoded",
          "X-CSRF-Token" => token,
        },
        body: "foo=bar"
      )
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "CSRF token is missing"
      response.status.should eq 403
    end

    it "returns a 403 unsafe requests if the persisted CSRF token does not have the expected size" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Content-Type" => "application/x-www-form-urlencoded",
          "X-CSRF-Token" => token,
        },
        body: "foo=bar"
      )
      raw_request.cookies["csrftoken"] = "invalid"
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "CSRF token does not have the expected size"
      response.status.should eq 403
    end

    it "returns a 403 unsafe requests if the persisted CSRF token contains unexpected characters" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Content-Type" => "application/x-www-form-urlencoded",
          "X-CSRF-Token" => token,
        },
        body: "foo=bar"
      )
      raw_request.cookies["csrftoken"] = "a" * 63 + "#"
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "CSRF token contains invalid characters"
      response.status.should eq 403
    end

    it "returns a 403 if the no CSRF token is specified as part of the request" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Content-Type" => "application/x-www-form-urlencoded",
        },
        body: "foo=bar"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "CSRF token is missing"
      response.status.should eq 403
    end

    it "returns a 403 if the the CSRF token specified as part of the request is invalid" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Content-Type" => "application/x-www-form-urlencoded",
          "X-CSRF-Token" => "invalid",
        },
        body: "foo=bar"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Invalid CSRF token format"
      response.status.should eq 403
    end

    it "returns a 403 if the the CSRF token specified as part of the request does not match the persisted one" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"         => "example.com",
          "Content-Type" => "application/x-www-form-urlencoded",
          "X-CSRF-Token" => "a" * 64,
        },
        body: "foo=bar"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      response = handler.process_dispatch

      response.content.should eq "Invalid CSRF token"
      response.status.should eq 403
    end
  end

  describe "#get_csrf_token" do
    it "generates a new token if no one was already set and forces it to be persisted" do
      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"}
      )
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandlerWithTokenAccess.new(request)
      response = handler.process_dispatch

      response.cookies["csrftoken"]?.should_not be_nil
    end

    it "refreshes the masked version of the original token" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "POST",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
        body: "foo=bar&csrftoken=#{token}"
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandler.new(request)
      handler.process_dispatch

      new_token = handler.get_csrf_token

      new_token.should_not eq token
      handler._perform_unmasking(new_token).should eq Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_SECRET
    end

    it "does not change the initial value of the cookie if it was already set" do
      token = Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_MASKED_SECRET_1

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"}
      )
      raw_request.cookies["csrftoken"] = token
      request = Marten::HTTP::Request.new(raw_request)

      handler = Marten::Handlers::RequestForgeryProtectionSpec::TestHandlerWithTokenAccess.new(request)
      response = handler.process_dispatch

      new_token = response.content

      new_token.should_not eq token
      handler._perform_unmasking(new_token).should eq Marten::Handlers::RequestForgeryProtectionSpec::EXAMPLE_SECRET

      response.cookies["csrftoken"].should eq token
    end
  end
end

module Marten::Handlers::RequestForgeryProtectionSpec
  EXAMPLE_SECRET          = "hTJ5wBtIS8PDdtl87dKnxipaGiNjniE8"
  EXAMPLE_MASKED_SECRET_1 = "p8vDuGBeukHERfcivhmj27RzqR2Jm1pNyR6yS9WOcim9WApgsmYypf8BY1FUB_VL"
  EXAMPLE_MASKED_SECRET_2 = "dgTB07gL9s-alvSG7MFEp-RoFei_vG-ym1swmyBjRqPFqQ5E4RfTOi8qboXkKQEw"

  class TestRequest < Marten::HTTP::Request
    def test_disable_request_forgery_protection=(value)
      self.disable_request_forgery_protection = value
    end
  end

  class TestHandler < Marten::Handler
    include Marten::Handlers::RequestForgeryProtection

    def delete
      respond "OK_DELETE"
    end

    def get
      respond "OK_GET"
    end

    def head
      respond "OK_HEAD"
    end

    def options
      respond "OK_OPTIONS"
    end

    def patch
      respond "OK_PATCH"
    end

    def post
      respond "OK_POST"
    end

    def put
      respond "OK_PUT"
    end

    def trace
      respond "OK_TRACE"
    end

    def _csrf_token
      csrf_token
    end

    def _perform_masking(v)
      mask_cipher_secret(v)
    end

    def _perform_unmasking(v)
      unmask_cipher_token(v)
    end
  end

  class TestHandlerWithTokenAccess < Marten::Handler
    include Marten::Handlers::RequestForgeryProtection

    def get
      respond get_csrf_token
    end

    def _perform_masking(v)
      mask_cipher_secret(v)
    end

    def _perform_unmasking(v)
      unmask_cipher_token(v)
    end
  end

  class TestHandlerWithProtectionEnabled < Marten::Handler
    include Marten::Handlers::RequestForgeryProtection

    protect_from_forgery true
  end

  class TestHandlerWithProtectionDisabled < Marten::Handler
    include Marten::Handlers::RequestForgeryProtection

    protect_from_forgery false

    def post
      respond "OK"
    end
  end
end
