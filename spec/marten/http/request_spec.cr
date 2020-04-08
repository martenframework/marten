require "./spec_helper"

describe Marten::HTTP::Request do
  before_each do
    Marten.settings.allowed_hosts = ["example.com"]
  end

  after_each do
    Marten.settings.allowed_hosts = [] of String
    Marten.settings.debug = false
    Marten.settings.use_x_forwarded_host = false
  end

  describe "::new" do
    it "allows to initialize a request by specifying a standard HTTP::Request object" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.nil?.should be_false
    end

    it "overrides the request's body IO in order to use a memory IO" do
      request = Marten::HTTP::RequestSpec::TestRequest.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      request.wrapped_request.body.should be_a IO::Memory
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
            "Host" => "example.com",
            "Content-Type" => "multipart/form-data; boundary=---------------------------735323031399963166993862150"
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
end

module Marten::HTTP::RequestSpec
  class TestRequest < Marten::HTTP::Request
    def wrapped_request
      @request
    end
  end
end
