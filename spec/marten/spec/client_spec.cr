require "./spec_helper"

describe Marten::Spec::Client do
  describe "#cookies" do
    it "returns a cookies store" do
      client = Marten::Spec::Client.new

      client.cookies.should be_a Marten::HTTP::Cookies
    end
  end

  describe "#delete" do
    it "returns the response returned by the handler matched by the specified path" do
      client = Marten::Spec::Client.new

      response = client.delete(Marten.routes.reverse("request_method_respond"))

      response.content.should eq "DELETE"
    end

    it "uses the expected content type by default" do
      client = Marten::Spec::Client.new

      response = client.delete(Marten.routes.reverse("headers_respond"))

      headers = JSON.parse(response.content)
      headers["Content-Type"].should eq "application/octet-stream"
    end
  end

  describe "#get" do
    it "returns the response returned by the handler matched by the specified path" do
      client = Marten::Spec::Client.new

      response = client.get(Marten.routes.reverse("request_method_respond"))

      response.content.should eq "GET"
    end

    it "forwards query parameters expressed as a hash as expected" do
      client = Marten::Spec::Client.new

      response = client.get(
        Marten.routes.reverse("query_params_respond"),
        query_params: {"foo" => "bar", "fruits" => ["orange", "apple"]}
      )

      response.content.should eq "foo=bar&fruits=orange&fruits=apple"
    end

    it "forwards query parameters expressed as a named tuple as expected" do
      client = Marten::Spec::Client.new

      response = client.get(
        Marten.routes.reverse("query_params_respond"),
        query_params: {foo: "bar", fruits: ["orange", "apple"]}
      )

      response.content.should eq "foo=bar&fruits=orange&fruits=apple"
    end

    it "uses the expected content type by default" do
      client = Marten::Spec::Client.new

      response = client.get(Marten.routes.reverse("headers_respond"))

      headers = JSON.parse(response.content)
      headers["Content-Type"].should eq "application/octet-stream"
    end

    it "uses the client-wide content type over the default one" do
      client = Marten::Spec::Client.new(content_type: "application/javascript")

      response = client.get(Marten.routes.reverse("headers_respond"))

      headers = JSON.parse(response.content)
      headers["Content-Type"].should eq "application/javascript"
    end

    it "provides the ability to specify a custom content type" do
      client = Marten::Spec::Client.new

      response = client.get(Marten.routes.reverse("headers_respond"), content_type: "application/javascript")

      headers = JSON.parse(response.content)
      headers["Content-Type"].should eq "application/javascript"
    end

    it "uses client-level headers as expected" do
      client = Marten::Spec::Client.new
      client.headers["X-Foo"] = "BAR"

      response = client.get(Marten.routes.reverse("headers_respond"))

      headers = JSON.parse(response.content)
      headers["X-Foo"].should eq "BAR"
    end

    it "provides the ability to specify custom header values expressed as a hash" do
      client = Marten::Spec::Client.new

      response = client.get(Marten.routes.reverse("headers_respond"), headers: {"X-Foo" => "BAR"})

      headers = JSON.parse(response.content)
      headers["X-Foo"].should eq "BAR"
    end

    it "provides the ability to specify custom header values expressed as a named tuple" do
      client = Marten::Spec::Client.new

      response = client.get(Marten.routes.reverse("headers_respond"), headers: {"X-Foo": "BAR"})

      headers = JSON.parse(response.content)
      headers["X-Foo"].should eq "BAR"
    end

    it "issues unsecure requests by default" do
      client = Marten::Spec::Client.new

      response = client.get(Marten.routes.reverse("secure_request_require"))

      response.status.should eq 403
    end

    it "can issue secure requests" do
      client = Marten::Spec::Client.new

      response = client.get(Marten.routes.reverse("secure_request_require"), secure: true)

      response.status.should eq 200
    end

    it "properly sets and forwards session store values for issued requests" do
      client = Marten::Spec::Client.new

      client.session["foo"] = "bar"

      response = client.get(Marten.routes.reverse("session_value_get"))

      response.status.should eq 200
      response.content.should eq "bar"
    end

    it "properly updates the session store with the session values set by the handler after performing the request" do
      client = Marten::Spec::Client.new

      response = client.get(Marten.routes.reverse("session_value_set"))

      response.status.should eq 200
      client.session["foo"]?.should eq "bar"
    end

    it "properly sets and forwards cookies store values for issued requests" do
      client = Marten::Spec::Client.new

      client.cookies["foo"] = "bar"

      response = client.get(Marten.routes.reverse("cookie_value_get"))

      response.status.should eq 200
      response.content.should eq "bar"
    end

    it "properly updates the cookies store with the cookie values set by the handler after performing the request" do
      client = Marten::Spec::Client.new

      response = client.get(Marten.routes.reverse("cookie_value_set"))

      response.status.should eq 200
      client.cookies["foo"]?.should eq "bar"
    end
  end

  describe "#head" do
    it "returns the response returned by the handler matched by the specified path" do
      client = Marten::Spec::Client.new

      response = client.head(Marten.routes.reverse("request_method_respond"))

      response.content.should eq "HEAD"
    end
  end

  describe "#headers" do
    it "returns a headers object" do
      client = Marten::Spec::Client.new

      client.headers.should be_a Marten::HTTP::Headers
    end
  end

  describe "#options" do
    it "returns the response returned by the handler matched by the specified path" do
      client = Marten::Spec::Client.new

      response = client.options(Marten.routes.reverse("request_method_respond"))

      response.content.should eq "OPTIONS"
    end

    it "uses the expected content type by default" do
      client = Marten::Spec::Client.new

      response = client.options(Marten.routes.reverse("headers_respond"))

      headers = JSON.parse(response.content)
      headers["Content-Type"].should eq "application/octet-stream"
    end
  end

  describe "#patch" do
    it "returns the response returned by the handler matched by the specified path" do
      client = Marten::Spec::Client.new

      response = client.patch(Marten.routes.reverse("request_method_respond"))

      response.content.should eq "PATCH"
    end

    it "uses the expected content type by default" do
      client = Marten::Spec::Client.new

      response = client.patch(Marten.routes.reverse("headers_respond"))

      headers = JSON.parse(response.content)
      headers["Content-Type"].should eq "application/octet-stream"
    end

    it "forwards parameters as expected" do
      client = Marten::Spec::Client.new

      response = client.patch(
        Marten.routes.reverse("simple_schema"),
        data: {first_name: "John", last_name: "Doe"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 302
    end
  end

  describe "#post" do
    it "returns the response returned by the handler matched by the specified path" do
      client = Marten::Spec::Client.new

      response = client.post(Marten.routes.reverse("request_method_respond"))

      response.content.should eq "POST"
    end

    it "forwards data parameters expressed as a hash as expected" do
      client = Marten::Spec::Client.new

      response = client.post(
        Marten.routes.reverse("simple_schema"),
        data: {"first_name" => "John", "last_name" => "Doe"}
      )

      response.status.should eq 302
    end

    it "forwards data parameters expressed as a named tuple as expected" do
      client = Marten::Spec::Client.new

      response = client.post(
        Marten.routes.reverse("simple_schema"),
        data: {first_name: "John", last_name: "Doe"}
      )

      response.status.should eq 302
    end

    it "supports uploading files with field files" do
      Marten.media_files_storage.write("css/app.css", IO::Memory.new("html { background: white; }"))
      field = Marten::DB::Field::File.new("my_field")
      file = Marten::DB::Field::File::File.new(field, "css/app.css")

      client = Marten::Spec::Client.new

      response = client.post(
        Marten.routes.reverse("simple_file_schema"),
        data: {label: "Test file", file: file}
      )

      response.status.should eq 302
    end

    it "supports uploading files with IOs" do
      client = Marten::Spec::Client.new

      response = client.post(
        Marten.routes.reverse("simple_file_schema"),
        data: {label: "Test file", file: IO::Memory.new("html { background: white; }")}
      )

      response.status.should eq 302
    end

    it "uses the expected content type by default" do
      client = Marten::Spec::Client.new

      response = client.post(Marten.routes.reverse("headers_respond"))

      headers = JSON.parse(response.content)
      headers["Content-Type"].should eq "multipart/form-data; boundary=B0UnDaRyUnIqU3"
    end

    it "supports url encoded data parameters" do
      client = Marten::Spec::Client.new

      response = client.post(
        Marten.routes.reverse("simple_schema"),
        data: {first_name: "John", last_name: "Doe"},
        content_type: "application/x-www-form-urlencoded"
      )

      response.status.should eq 302
    end

    it "supports JSON data parameters" do
      client = Marten::Spec::Client.new

      response = client.post(
        Marten.routes.reverse("simple_schema"),
        data: {first_name: "John", last_name: "Doe"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 302
    end
  end

  describe "#put" do
    it "returns the response returned by the handler matched by the specified path" do
      client = Marten::Spec::Client.new

      response = client.put(Marten.routes.reverse("request_method_respond"))

      response.content.should eq "PUT"
    end

    it "uses the expected content type by default" do
      client = Marten::Spec::Client.new

      response = client.put(Marten.routes.reverse("headers_respond"))

      headers = JSON.parse(response.content)
      headers["Content-Type"].should eq "application/octet-stream"
    end

    it "forwards parameters as expected" do
      client = Marten::Spec::Client.new

      response = client.put(
        Marten.routes.reverse("simple_schema"),
        data: {first_name: "John", last_name: "Doe"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 302
    end
  end

  describe "#session" do
    it "returns a session store and sets the associated session key in the cookies" do
      client = Marten::Spec::Client.new

      client.session.should be_a Marten::HTTP::Session::Store::Base
      client.cookies[Marten.settings.sessions.cookie_name].should eq client.session.session_key
    end
  end

  describe "#trace" do
    it "returns the response returned by the handler matched by the specified path" do
      client = Marten::Spec::Client.new

      response = client.trace(Marten.routes.reverse("request_method_respond"))

      response.content.should eq "TRACE"
    end
  end
end
