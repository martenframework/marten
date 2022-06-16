require "./spec_helper"

describe Marten::Middleware::Session do
  describe "#call" do
    it "associates a session store to the request when a session cookie is present" do
      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = "sessionkey"
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.session.should be_a Marten::HTTP::Session::Store::Cookie
      request.session.session_key.should eq "sessionkey"
    end

    it "associates a session store to the request when a session cookie is not present" do
      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.session.should be_a Marten::HTTP::Session::Store::Cookie
      request.session.session_key.should be_nil
    end

    it "associates a session store to the request by using the configured cookie name" do
      with_overridden_setting("sessions.cookie_name", "othercookie") do
        raw_request = ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
        raw_request.cookies["othercookie"] = "sessionkey"
        request = Marten::HTTP::Request.new(raw_request)

        middleware = Marten::Middleware::Session.new
        middleware.call(
          request,
          ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
        )

        request.session.should be_a Marten::HTTP::Session::Store::Cookie
        request.session.session_key.should eq "sessionkey"
      end
    end

    it "removes the session cookie if the store is empty" do
      encryptor = Marten::Core::Encryptor.new
      session_key = encryptor.encrypt(Hash(String, String).new.to_json)

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = session_key
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.cookies.has_key?(Marten.settings.sessions.cookie_name).should be_false
    end

    it "patches the Vary header when removing the session cookie because the store is empty" do
      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = "test"
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{
          request.session.flush
          Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
        }
      )

      response.cookies.has_key?(Marten.settings.sessions.cookie_name).should be_false
      response.headers[:VARY].should eq "Cookie"
    end

    it "removes the session cookie if the store is empty when using a custom cookie name" do
      with_overridden_setting("sessions.cookie_name", "othercookie") do
        encryptor = Marten::Core::Encryptor.new
        session_key = encryptor.encrypt(Hash(String, String).new.to_json)

        raw_request = ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
        raw_request.cookies["othercookie"] = session_key
        request = Marten::HTTP::Request.new(raw_request)

        middleware = Marten::Middleware::Session.new
        response = middleware.call(
          request,
          ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
        )

        response.cookies.has_key?("othercookie").should be_false
      end
    end

    it "patches the Vary header if the session store was accessed during the request-response cycle" do
      encryptor = Marten::Core::Encryptor.new
      session_key = encryptor.encrypt({"foo" => "bar"}.to_json)

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = session_key
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{
          request.session["foo"]?
          Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
        }
      )

      response.headers[:VARY].should eq "Cookie"
    end

    it "does not patch the Vary header if the session store was not accessed during the request-response cycle" do
      encryptor = Marten::Core::Encryptor.new
      session_key = encryptor.encrypt({"foo" => "bar"}.to_json)

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = session_key
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.headers[:VARY]?.should be_nil
    end

    it "does not set the session cookie if the session store was not modified" do
      encryptor = Marten::Core::Encryptor.new
      session_key = encryptor.encrypt({"foo" => "bar"}.to_json)

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = session_key
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.cookies[Marten.settings.sessions.cookie_name]?.should be_nil
    end

    it "does not set the session cookie if the response is a server error" do
      encryptor = Marten::Core::Encryptor.new
      session_key = encryptor.encrypt({"foo" => "bar"}.to_json)

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = session_key
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{
          request.session["other"] = "test"
          Marten::HTTP::Response.new("It does not work!", content_type: "text/plain", status: 500)
        }
      )

      response.cookies[Marten.settings.sessions.cookie_name]?.should be_nil
    end

    it "sets the cookie using the expected cookie name and value when the session store is modified" do
      encryptor = Marten::Core::Encryptor.new

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{
          request.session["other"] = "test"
          Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
        }
      )

      session_key = response.cookies[Marten.settings.sessions.cookie_name]
      encryptor.decrypt!(session_key).should eq({"foo" => "bar", "other" => "test"}.to_json)
    end

    it "sets the cookie using a custom cookie name when the session store is modified" do
      with_overridden_setting("sessions.cookie_name", "othercookie") do
        encryptor = Marten::Core::Encryptor.new

        raw_request = ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
        raw_request.cookies["othercookie"] = encryptor.encrypt({"foo" => "bar"}.to_json)
        request = Marten::HTTP::Request.new(raw_request)

        middleware = Marten::Middleware::Session.new
        response = middleware.call(
          request,
          ->{
            request.session["other"] = "test"
            Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          }
        )

        session_key = response.cookies["othercookie"]
        encryptor.decrypt!(session_key).should eq({"foo" => "bar", "other" => "test"}.to_json)
      end
    end

    it "sets the cookie using the expected expiry time when the session store is modified" do
      time = Time.local
      Timecop.freeze(time) do
        encryptor = Marten::Core::Encryptor.new

        raw_request = ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
        raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
        request = Marten::HTTP::Request.new(raw_request)

        middleware = Marten::Middleware::Session.new
        response = middleware.call(
          request,
          ->{
            request.session["other"] = "test"
            Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          }
        )

        raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
        raw_cookie.expires.should eq time + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)
      end
    end

    it "sets the cookie using a custom expiry time when the session store is modified" do
      with_overridden_setting("sessions.cookie_max_age", 25_000) do
        time = Time.local
        Timecop.freeze(time) do
          encryptor = Marten::Core::Encryptor.new

          raw_request = ::HTTP::Request.new(
            method: "GET",
            resource: "/test/xyz",
            headers: HTTP::Headers{"Host" => "example.com"},
          )
          raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
          request = Marten::HTTP::Request.new(raw_request)

          middleware = Marten::Middleware::Session.new
          response = middleware.call(
            request,
            ->{
              request.session["other"] = "test"
              Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
            }
          )

          raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
          raw_cookie.expires.should eq time + Time::Span.new(seconds: 25_000)
        end
      end
    end

    it "sets the cookie using the expected domain when the session store is modified" do
      encryptor = Marten::Core::Encryptor.new

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{
          request.session["other"] = "test"
          Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
        }
      )

      raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
      raw_cookie.domain.should be_nil
    end

    it "sets the cookie using a custom domain when the session store is modified" do
      with_overridden_setting("sessions.cookie_domain", "example.com", nilable: true) do
        encryptor = Marten::Core::Encryptor.new

        raw_request = ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
        raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
        request = Marten::HTTP::Request.new(raw_request)

        middleware = Marten::Middleware::Session.new
        response = middleware.call(
          request,
          ->{
            request.session["other"] = "test"
            Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          }
        )

        raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
        raw_cookie.domain.should eq "example.com"
      end
    end

    it "sets the cookie using the expected secure configuration when the session store is modified" do
      encryptor = Marten::Core::Encryptor.new

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{
          request.session["other"] = "test"
          Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
        }
      )

      raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
      raw_cookie.secure.should be_false
    end

    it "sets the cookie using a custom secure configuration when the session store is modified" do
      with_overridden_setting("sessions.cookie_secure", true) do
        encryptor = Marten::Core::Encryptor.new

        raw_request = ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
        raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
        request = Marten::HTTP::Request.new(raw_request)

        middleware = Marten::Middleware::Session.new
        response = middleware.call(
          request,
          ->{
            request.session["other"] = "test"
            Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          }
        )

        raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
        raw_cookie.secure.should be_true
      end
    end

    it "sets the cookie using the expected HTTP-only configuration when the session store is modified" do
      encryptor = Marten::Core::Encryptor.new

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{
          request.session["other"] = "test"
          Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
        }
      )

      raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
      raw_cookie.http_only.should be_false
    end

    it "sets the cookie using a custom HTTP-only configuration when the session store is modified" do
      with_overridden_setting("sessions.cookie_http_only", true) do
        encryptor = Marten::Core::Encryptor.new

        raw_request = ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
        raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
        request = Marten::HTTP::Request.new(raw_request)

        middleware = Marten::Middleware::Session.new
        response = middleware.call(
          request,
          ->{
            request.session["other"] = "test"
            Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          }
        )

        raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
        raw_cookie.http_only.should be_true
      end
    end

    it "sets the cookie using the same-site configuration when the session store is modified" do
      encryptor = Marten::Core::Encryptor.new

      raw_request = ::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
      request = Marten::HTTP::Request.new(raw_request)

      middleware = Marten::Middleware::Session.new
      response = middleware.call(
        request,
        ->{
          request.session["other"] = "test"
          Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
        }
      )

      raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
      raw_cookie.samesite.should eq ::HTTP::Cookie::SameSite::Lax
    end

    it "sets the cookie using a custom same-site configuration when the session store is modified" do
      with_overridden_setting("sessions.cookie_same_site", "Strict") do
        encryptor = Marten::Core::Encryptor.new

        raw_request = ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
        raw_request.cookies[Marten.settings.sessions.cookie_name] = encryptor.encrypt({"foo" => "bar"}.to_json)
        request = Marten::HTTP::Request.new(raw_request)

        middleware = Marten::Middleware::Session.new
        response = middleware.call(
          request,
          ->{
            request.session["other"] = "test"
            Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
          }
        )

        raw_cookie = response.cookies.to_stdlib[Marten.settings.sessions.cookie_name]
        raw_cookie.samesite.should eq ::HTTP::Cookie::SameSite::Strict
      end
    end
  end
end
