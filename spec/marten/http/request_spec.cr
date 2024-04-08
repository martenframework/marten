require "./spec_helper"

describe Marten::HTTP::Request do
  around_each do |t|
    original_allowed_hosts = Marten.settings.allowed_hosts
    original_debug = Marten.settings.debug
    original_use_x_forwarded_host = Marten.settings.use_x_forwarded_host

    Marten.settings.allowed_hosts = %w(example.com)

    t.run

    Marten.settings.allowed_hosts = original_allowed_hosts
    Marten.settings.debug = original_debug
    Marten.settings.use_x_forwarded_host = original_use_x_forwarded_host
  end

  describe "::new" do
    it "allows to initialize a request by specifying a standard HTTP::Request object" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "",
        headers: HTTP::Headers{"Host" => "example.com"}
      )
      request.nil?.should be_false
    end

    it "overrides the request's body IO in order to use a memory IO" do
      request = Marten::HTTP::RequestSpec::TestRequest.new(
        method: "GET",
        resource: "",
        headers: HTTP::Headers{"Host" => "example.com"}
      )

      request.wrapped_request.body.should be_a IO::Memory
    end
  end

  describe "#accepts?" do
    it "returns true if the passed media type is supported by the request" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        body: "foo=bar",
        headers: HTTP::Headers{
          "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp",
        }
      )

      request.accepts?("text/html").should be_true
      request.accepts?("application/xhtml+xml").should be_true
      request.accepts?("application/xml").should be_true
      request.accepts?("image/webp").should be_true
    end

    it "returns true in all cases if the Accept header contains */*" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          body: "foo=bar",
          headers: HTTP::Headers{
            "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
          }
        )
      )

      request.accepts?("*/*").should be_true
      request.accepts?("image/jpeg").should be_true
    end

    it "returns false if the passed media type is not supported by the request" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          body: "foo=bar",
          headers: HTTP::Headers{
            "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp",
          }
        )
      )

      request.accepts?("*/*").should be_false
      request.accepts?("image/jpeg").should be_false
    end
  end

  describe "#accepted_media_types" do
    it "returns the media types accepted by the request" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          body: "foo=bar",
          headers: HTTP::Headers{
            "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp",
          }
        )
      )

      request.accepted_media_types.size.should eq 4
      request.accepted_media_types[0].should eq MIME::MediaType.parse("text/html")
      request.accepted_media_types[1].should eq MIME::MediaType.parse("application/xhtml+xml")
      request.accepted_media_types[2].should eq MIME::MediaType.parse("application/xml;q=0.9")
      request.accepted_media_types[3].should eq MIME::MediaType.parse("image/webp")
    end

    it "ignores possibly empty or malformed media types" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          body: "foo=bar",
          headers: HTTP::Headers{
            "Accept" => "text/html,,,application/xhtml+xml,  ,application/xml;q=0.9,image/webp",
          }
        )
      )

      request.accepted_media_types.size.should eq 4
      request.accepted_media_types[0].should eq MIME::MediaType.parse("text/html")
      request.accepted_media_types[1].should eq MIME::MediaType.parse("application/xhtml+xml")
      request.accepted_media_types[2].should eq MIME::MediaType.parse("application/xml;q=0.9")
      request.accepted_media_types[3].should eq MIME::MediaType.parse("image/webp")
    end

    it "fallbacks to the any MIME type if no Accept header is present" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          body: "foo=bar",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      request.accepted_media_types.size.should eq 1
      request.accepted_media_types[0].should eq MIME::MediaType.parse("*/*")
    end
  end

  describe "#body" do
    it "returns the request body" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          body: "foo=bar",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.body.should eq "foo=bar"
    end

    it "returns an empty string if the request has no body" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.body.should eq ""
    end
  end

  describe "#content_security_policy" do
    it "returns nil by default" do
      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")

      request.content_security_policy.should be_nil
    end

    it "returns the assigned Content-Security-Policy object" do
      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")

      csp = Marten::HTTP::ContentSecurityPolicy.new
      request.content_security_policy = csp

      request.content_security_policy.should eq csp
    end
  end

  describe "#content_security_policy=" do
    it "allows to assign a Content-Security-Policy object to the request" do
      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")

      csp = Marten::HTTP::ContentSecurityPolicy.new
      request.content_security_policy = csp

      request.content_security_policy.should eq csp
    end

    it "can be used to reset a previously assigned Content-Security-Policy object" do
      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")

      csp = Marten::HTTP::ContentSecurityPolicy.new
      request.content_security_policy = csp
      request.content_security_policy = nil

      request.content_security_policy.should be_nil
    end
  end

  describe "#content_security_policy_nonce" do
    it "returns a Base64 value" do
      request_1 = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")
      request_2 = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")

      request_1.content_security_policy_nonce.size.should eq 22
      request_2.content_security_policy_nonce.size.should eq 22
      request_1.content_security_policy_nonce.should_not eq request_2.content_security_policy_nonce
    end
  end

  describe "#cookies" do
    it "returns the request cookies" do
      raw_request = ::HTTP::Request.new(method: "GET", resource: "/test/xyz")
      raw_request.cookies["test"] = "value"

      request = Marten::HTTP::Request.new(raw_request)

      request.cookies.should be_a Marten::HTTP::Cookies
      request.cookies.size.should eq 1
      request.cookies["test"].should eq "value"
    end
  end

  describe "#data" do
    it "returns an object containing the params extracted from application/x-www-form-urlencoded inputs" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=bar&test=xyz&foo=baz"
        )
      )
      request.data.should be_a Marten::HTTP::Params::Data
      request.data.size.should eq 3
      request.data.fetch_all("foo").should eq ["bar", "baz"]
      request.data.fetch_all("test").should eq ["xyz"]
    end

    it "returns an object containing the params extracted from multipart/form-data inputs" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{
            "Host"         => "example.com",
            "Content-Type" => "multipart/form-data; boundary=---------------------------735323031399963166993862150",
          },
          body: <<-FORMDATA
          -----------------------------735323031399963166993862150
          Content-Disposition: form-data; name="text"

          hello
          -----------------------------735323031399963166993862150
          Content-Disposition: form-data; name="file"; filename="a.txt"
          Content-Type: text/plain

          Content of a.txt.
          -----------------------------735323031399963166993862150
          Content-Disposition: form-data; name="file2"; filename="a.html"
          Content-Type: text/html

          <!DOCTYPE html><title>Content of a.html.</title>
          -----------------------------735323031399963166993862150
          Content-Disposition: form-data; name="file2"; filename="b.html"
          Content-Type: text/html

          <!DOCTYPE html><title>Content of b.html.</title>
          -----------------------------735323031399963166993862150--
          FORMDATA
            .gsub('\n', "\r\n")
        )
      )
      request.data.should be_a Marten::HTTP::Params::Data
      request.data.size.should eq 4
      request.data.fetch_all("text").should eq ["hello"]
      request.data.fetch_all("file").not_nil!.size.should eq 1
      request.data["file"].should be_a Marten::HTTP::UploadedFile
      request.data.fetch_all("file2").not_nil!.size.should eq 2
      request.data.fetch_all("file2").not_nil!.[0].should be_a Marten::HTTP::UploadedFile
      request.data.fetch_all("file2").not_nil!.[1].should be_a Marten::HTTP::UploadedFile
    end

    it "returns an object containing the params extracted from application/json inputs" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/json"},
          body: %{{"foo": "bar", "test": "xyz"}}
        )
      )
      request.data.should be_a Marten::HTTP::Params::Data
      request.data.size.should eq 2
      request.data.fetch_all("foo").should eq ["bar"]
      request.data.fetch_all("test").should eq ["xyz"]
    end

    it "returns an object without parsed params if the content type is not supported" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/unknown"},
          body: "dummy"
        )
      )
      request.data.should be_a Marten::HTTP::Params::Data
      request.data.size.should eq 0
    end
  end

  describe "#delete?" do
    it "returns true if the request is a DELETE" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "DELETE",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.delete?.should be_true
    end

    it "returns false if the request is not a DELETE" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.delete?.should be_false
    end
  end

  describe "#disable_request_forgery_protection=" do
    it "allows to set a flag indicating to disable request forgery protection for test purposes" do
      request = Marten::HTTP::RequestSpec::TestRequest.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"}
      )

      request.test_disable_request_forgery_protection = true

      request.test_disable_request_forgery_protection?.should be_true
    end
  end

  describe "#disable_request_forgery_protection?" do
    it "always returns false by default" do
      request = Marten::HTTP::RequestSpec::TestRequest.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"}
      )

      request.test_disable_request_forgery_protection?.should be_false
    end

    it "returns true if the corresponding flag was set to disable request forgery protection for test purposes" do
      request = Marten::HTTP::RequestSpec::TestRequest.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"}
      )

      request.test_disable_request_forgery_protection = true

      request.test_disable_request_forgery_protection?.should be_true
    end
  end

  describe "#flash" do
    it "returns the flash store if it was set previously" do
      flash_store = Marten::HTTP::FlashStore.new

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.flash = flash_store

      request.flash.should eq flash_store
    end

    it "raises the expected exception if the flash store was not set previously" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      expect_raises(Marten::HTTP::Errors::UnmetRequestCondition, "Flash store not available") { request.flash }
    end
  end

  describe "#flash?" do
    it "returns true if the flash store was set previously" do
      flash_store = Marten::HTTP::FlashStore.new

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.flash = flash_store

      request.flash?.should be_true
    end

    it "returns false if the flash store was not set previously" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      request.flash?.should be_false
    end
  end

  describe "#flash=" do
    it "allows to set the flash store associated with the request" do
      flash_store = Marten::HTTP::FlashStore.new

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.flash = flash_store

      request.flash.should eq flash_store
    end
  end

  describe "#full_path" do
    it "returns the request full path when query params are present" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.full_path.should eq "/test/xyz?foo=bar&foo=baz&xyz=test"
    end

    it "returns the request full path when query params are not present" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.full_path.should eq "/test/xyz"
    end
  end

  describe "#get?" do
    it "returns true if the request is a GET" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.get?.should be_true
    end

    it "returns false if the request is not a GET" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.get?.should be_false
    end
  end

  describe "#head?" do
    it "returns true if the request is a HEAD" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "HEAD",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.head?.should be_true
    end

    it "returns false if the request is not a HEAD" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.head?.should be_false
    end
  end

  describe "#headers" do
    it "returns the request headers" do
      headers = ::HTTP::Headers{"Content-Type" => "application/json", "Host" => "example.com"}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "/test/xyz", headers: headers)
      )
      request.headers.should be_a Marten::HTTP::Headers
      request.headers.size.should eq 2
      request.headers["Content-Type"].should eq "application/json"
      request.headers["Host"].should eq "example.com"
    end
  end

  describe "#host" do
    it "returns the request host" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.host.should eq "example.com"
    end

    it "raises UnexpectedHost if no host is specified in the headers" do
      expect_raises(Marten::HTTP::Errors::UnexpectedHost) do
        Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "")).host
      end
    end

    it "raises UnexpectedHost if the Host header value does not match one of the allowed hosts" do
      expect_raises(Marten::HTTP::Errors::UnexpectedHost) do
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "foobar.com"}
          )
        ).host
      end
    end

    it "raises UnexpectedHost if the X-Forwarded-Host header matches allowed hosts but the behaviour is disabled" do
      expect_raises(Marten::HTTP::Errors::UnexpectedHost) do
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"X-Forwarded-Host" => "example.com"}
          )
        ).host
      end
    end

    it "raises UnexpectedHost if the X-Forwarded-Host header don't match allowed hosts and the behaviour is enabled" do
      Marten.settings.use_x_forwarded_host = true
      expect_raises(Marten::HTTP::Errors::UnexpectedHost) do
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"X-Forwarded-Host" => "foobar.com"}
          )
        ).host
      end
    end

    it "does not raise if the X-Forwarded-Host header matches allowed hosts and the behaviour is enabled" do
      Marten.settings.use_x_forwarded_host = true
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"X-Forwarded-Host" => "example.com"}
        )
      )
      request.host.should eq "example.com"
    end

    it "is able to process hosts containing ports" do
      Marten.settings.allowed_hosts = ["example.com", "127.0.0.1"]

      request_1 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers{"Host" => "example.com:8080"})
      )
      request_1.host.should eq "example.com:8080"

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "POST", resource: "", headers: HTTP::Headers{"Host" => "127.0.0.1:8000"})
      )
      request_2.host.should eq "127.0.0.1:8000"
    end

    it "allows hosts that correspond to subdomains of configured wildcard domains" do
      Marten.settings.allowed_hosts = [".example.com"]

      request_1 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers{"Host" => "foo.example.com"})
      )
      request_1.host.should eq "foo.example.com"

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "POST", resource: "", headers: HTTP::Headers{"Host" => "bar.xyz.example.com:8080"})
      )
      request_2.host.should eq "bar.xyz.example.com:8080"

      request_3 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers{"Host" => "example.com"})
      )
      request_3.host.should eq "example.com"
    end

    it "allows all hosts if a match all hosts is configured" do
      Marten.settings.allowed_hosts = ["*"]

      request_1 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers{"Host" => "foo.example.com"})
      )
      request_1.host.should eq "foo.example.com"

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "POST", resource: "", headers: HTTP::Headers{"Host" => "dummy.com"})
      )
      request_2.host.should eq "dummy.com"
    end

    it "allows IPv4 addresses as hosts if configured" do
      Marten.settings.allowed_hosts = ["192.168.12.46"]

      request_1 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers{"Host" => "192.168.12.46"})
      )
      request_1.host.should eq "192.168.12.46"

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "POST", resource: "", headers: HTTP::Headers{"Host" => "192.168.12.46:8000"})
      )
      request_2.host.should eq "192.168.12.46:8000"
    end

    it "allows IPv6 addresses as hosts if configured" do
      Marten.settings.allowed_hosts = ["[fedc:ba98:7654:3210:fedc:ba98:7654:3210]"]

      request_1 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "[fedc:ba98:7654:3210:fedc:ba98:7654:3210]"}
        )
      )
      request_1.host.should eq "[fedc:ba98:7654:3210:fedc:ba98:7654:3210]"

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "[fedc:ba98:7654:3210:fedc:ba98:7654:3210]:8000"}
        )
      )
      request_2.host.should eq "[fedc:ba98:7654:3210:fedc:ba98:7654:3210]:8000"
    end

    it "allows hosts that end with a '.'" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com."}
        )
      )
      request.host.should eq "example.com."
    end

    it "allows local addresses by default if none is configured in debug mode" do
      Marten.settings.allowed_hosts = [] of String
      Marten.settings.debug = true

      request_1 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "POST", resource: "", headers: HTTP::Headers{"Host" => "127.0.0.1:8000"})
      )
      request_1.host.should eq "127.0.0.1:8000"

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "POST", resource: "", headers: HTTP::Headers{"Host" => "localhost:8000"})
      )
      request_2.host.should eq "localhost:8000"

      request_3 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "POST", resource: "", headers: HTTP::Headers{"Host" => "[::1]:8000"})
      )
      request_3.host.should eq "[::1]:8000"
    end
  end

  describe "#method" do
    it "returns the request method" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.method.should eq "GET"
    end
  end

  describe "#options?" do
    it "returns true if the request is an OPTIONS" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "OPTIONS",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.options?.should be_true
    end

    it "returns false if the request is not an OPTIONS" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.options?.should be_false
    end
  end

  describe "#path" do
    it "returns the request path" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.path.should eq "/test/xyz"
    end
  end

  describe "#patch?" do
    it "returns true if the request is a PATCH" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "PATCH",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.patch?.should be_true
    end

    it "returns false if the request is not a PATCH" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.patch?.should be_false
    end
  end

  describe "#port" do
    around_each do |t|
      original_use_x_forwarded_proto = Marten.settings.use_x_forwarded_proto

      t.run

      Marten.settings.use_x_forwarded_proto = original_use_x_forwarded_proto
    end

    it "returns the request port" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com:8080"}
        )
      )
      request.port.should eq "8080"
    end

    it "returns 80 by default if the host does not contain any port for an HTTP request" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.port.should eq "80"
    end

    it "returns 443 by default if the host does not contain any port for an HTTPS request" do
      Marten.settings.use_x_forwarded_proto = true

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{
            "Host"              => "example.com",
            "X-Forwarded-Proto" => "https",
          }
        )
      )

      request.port.should eq "443"
    end

    it "returns the X-Forwarded-Port header value if the corresponding setting is set to true" do
      Marten.settings.use_x_forwarded_port = true

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "X-Forwarded-Port" => "8080"}
        )
      )
      request.port.should eq "8080"
    end

    it "fallbacks to the default port if the X-Forwarded-Port header should be used but does not contain any value" do
      Marten.settings.use_x_forwarded_port = true

      request_1 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "X-Forwarded-Port" => ""}
        )
      )
      request_1.port.should eq "80"

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request_2.port.should eq "80"
    end
  end

  describe "#post?" do
    it "returns true if the request is a POST" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.post?.should be_true
    end

    it "returns false if the request is not a POST" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.post?.should be_false
    end
  end

  describe "#put?" do
    it "returns true if the request is a PUT" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "PUT",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.put?.should be_true
    end

    it "returns false if the request is not a PUT" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.put?.should be_false
    end
  end

  describe "#query_params" do
    it "returns the request query parameters" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.query_params.should be_a Marten::HTTP::Params::Query
      request.query_params.size.should eq 3
      request.query_params.fetch_all(:foo).should eq ["bar", "baz"]
      request.query_params.fetch_all(:xyz).should eq ["test"]
    end
  end

  describe "#scheme" do
    around_each do |t|
      original_use_x_forwarded_proto = Marten.settings.use_x_forwarded_proto

      t.run

      Marten.settings.use_x_forwarded_proto = original_use_x_forwarded_proto
    end

    it "returns http by default if the use_x_forwarded_proto setting is set to false" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.scheme.should eq "http"
    end

    it "returns https if the use_x_forwarded_proto setting is set to true and the header has the right value" do
      Marten.settings.use_x_forwarded_proto = true

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{
            "Host"              => "example.com",
            "X-Forwarded-Proto" => "https",
          }
        )
      )
      request.scheme.should eq "https"
    end

    it "returns http if the use_x_forwarded_proto setting is set to true and the header is not present" do
      Marten.settings.use_x_forwarded_proto = true

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.scheme.should eq "http"
    end

    it "returns http if the use_x_forwarded_proto setting is set to true and the header doesn't have the right value" do
      Marten.settings.use_x_forwarded_proto = true

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{
            "Host"              => "example.com",
            "X-Forwarded-Proto" => "https",
          }
        )
      )
      request.scheme.should eq "https"
    end
  end

  describe "#scheme=" do
    it "allows to set the request scheme for test purposes only" do
      request = Marten::HTTP::RequestSpec::TestRequest.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"}
      )

      request.test_scheme = "https"

      request.scheme.should eq "https"
      request.secure?.should be_true
    end
  end

  describe "#secure?" do
    around_each do |t|
      original_use_x_forwarded_proto = Marten.settings.use_x_forwarded_proto

      t.run

      Marten.settings.use_x_forwarded_proto = original_use_x_forwarded_proto
    end

    it "returns false if the scheme is not HTTPS" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      request.secure?.should be_false
    end

    it "returns true if the scheme is HTTPS" do
      Marten.settings.use_x_forwarded_proto = true

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{
            "Host"              => "example.com",
            "X-Forwarded-Proto" => "https",
          }
        )
      )

      request.secure?.should be_true
    end
  end

  describe "#session" do
    it "returns the session store if it was set previously" do
      session_store = Marten::HTTP::Session::Store::Cookie.new(nil)

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.session = session_store

      request.session.should eq session_store
    end

    it "raises the expected exception if the session store was not set previously" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      expect_raises(Marten::HTTP::Errors::UnmetRequestCondition, "Session store not available") { request.session }
    end
  end

  describe "#session?" do
    it "returns true if the session store was set previously" do
      session_store = Marten::HTTP::Session::Store::Cookie.new(nil)

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.session = session_store

      request.session?.should be_true
    end

    it "returns false if the session store was not set previously" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      request.session?.should be_false
    end
  end

  describe "#session=" do
    it "allows to set the session store associated with the request" do
      session_store = Marten::HTTP::Session::Store::Cookie.new(nil)

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.session = session_store

      request.session.should eq session_store
    end
  end

  describe "#trace?" do
    it "returns true if the request is a TRACE" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "TRACE",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.trace?.should be_true
    end

    it "returns false if the request is not a TRACE" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.trace?.should be_false
    end
  end
end

module Marten::HTTP::RequestSpec
  class TestRequest < Marten::HTTP::Request
    def wrapped_request
      @request
    end

    def test_disable_request_forgery_protection=(value)
      self.disable_request_forgery_protection = value
    end

    def test_disable_request_forgery_protection?
      self.disable_request_forgery_protection?
    end

    def test_scheme=(scheme)
      self.scheme = scheme
    end
  end
end
