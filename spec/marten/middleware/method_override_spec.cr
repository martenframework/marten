require "./spec_helper"

describe Marten::Middleware::MethodOverride do
  describe "#call" do
    it "does not override the request method if _method is not present" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.post?.should be_true
    end

    it "overrides a POST request with DELETE when _method=DELETE is in the body" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "_method=delete"
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.delete?.should be_true
    end

    it "overrides a POST request according to a X-Http-Method-Override header" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{
            "Host"                   => "example.com",
            "Content-Type"           => "application/x-www-form-urlencoded",
            "X-Http-Method-Override" => "DELETE",
          },
          body: "foo=bar"
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.delete?.should be_true
    end

    it "overrides a POST request with PUT using form input, even when a X-Http-Method-Override header is present" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{
            "Host"                   => "example.com",
            "Content-Type"           => "application/x-www-form-urlencoded",
            "X-Http-Method-Override" => "DELETE",
          },
          body: "_method=put"
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.put?.should be_true
    end

    it "does not override non-POST requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "_method=delete"
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.delete?.should be_false
    end

    it "does not override the method when _method parameter is empty" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "_method="
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.post?.should be_true
    end

    it "does not override the method when _method parameter is not allowed" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "_method=invalid"
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.post?.should be_true
    end

    it "does not override the method when the request data is json" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/json"},
          body: %{{"_method": "delete"}}
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.post?.should be_true
    end

    it "override the method for a multipart/form-data body with a valid _method input" do
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
          Content-Disposition: form-data; name="_method"

          delete
          -----------------------------735323031399963166993862150--
          FORMDATA
            .gsub('\n', "\r\n")
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.delete?.should be_true
    end

    it "does not override the method for a multipart/form-data body with an invalid _method input" do
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
          Content-Disposition: form-data; name="_method"

          invalid
          -----------------------------735323031399963166993862150--
          FORMDATA
            .gsub('\n', "\r\n")
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.post?.should be_true
    end

    it "does not override the method if _method is a file upload" do
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
          Content-Disposition: form-data; name="_method"; filename="a.txt"
          Content-Type: text/plain

          delete
          -----------------------------735323031399963166993862150--
          FORMDATA
            .gsub('\n', "\r\n")
        )
      )

      middleware = Marten::Middleware::MethodOverride.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.delete?.should_not be_true
    end
  end
end
