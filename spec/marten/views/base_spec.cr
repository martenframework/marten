require "./spec_helper"

describe Marten::Views::Base do
  describe "::new" do
    it "allows to initialize a view instance from an HTTP request object" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::Base.new(request)
      view.nil?.should be_false
      view.params.empty?.should be_true
    end

    it "allows to initialize a view instance from an HTTP request object and a hash of routing parameters" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      params_1 = Hash(String, Marten::Routing::Parameter::Types){"id" => 42}
      view_1 = Marten::Views::Base.new(request, params_1)
      view_1.params.should eq({"id" => 42})

      params_2 = Hash(String, Marten::Routing::Parameter::Types){"slug" => "my-slug"}
      view_2 = Marten::Views::Base.new(request, params_2)
      view_2.params.should eq({"slug" => "my-slug"})

      params_3 = Hash(String, Marten::Routing::Parameter::Types){
        "id" => ::UUID.new("a288e10f-fffe-46d1-b71a-436e9190cdc3"),
      }
      view_3 = Marten::Views::Base.new(request, params_3)
      view_3.params.should eq({"id" => ::UUID.new("a288e10f-fffe-46d1-b71a-436e9190cdc3")})
    end
  end

  describe "::http_method_names" do
    it "returns all the HTTP method names unless explicitely set" do
      Marten::Views::Base.http_method_names.should eq %w(get post put patch delete head options trace)
    end

    it "returns the configured HTTP method names if explictely set" do
      Marten::Views::BaseSpec::Test1View.http_method_names.should eq %w(get post options)
    end
  end

  describe "::http_method_names(*method_names)" do
    it "allows to set the supported HTTP method names using strings" do
      Marten::Views::BaseSpec::Test1View.http_method_names.should eq %w(get post options)
    end

    it "allows to set the supported HTTP method names using symbols" do
      Marten::Views::BaseSpec::Test2View.http_method_names.should eq %w(post put)
    end
  end

  describe "#request" do
    it "returns the request handled by the view" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::Base.new(request)
      view.request.should eq request
    end
  end

  describe "#params" do
    it "returns the routing parameters handled by the view" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      params = Hash(String, Marten::Routing::Parameter::Types){"id" => 42}
      view = Marten::Views::Base.new(request, params)
      view.params.should eq params
    end
  end

  describe "#dispatch" do
    it "returns an HTTP Not Allowed responses for GET requests by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::Base.new(request)
      response = view.dispatch
      response.status.should eq 405
    end

    it "returns an HTTP Not Allowed responses for POST requests by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::Base.new(request)
      response = view.dispatch
      response.status.should eq 405
    end

    it "returns an HTTP Not Allowed responses for PUT requests by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "PUT",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::Base.new(request)
      response = view.dispatch
      response.status.should eq 405
    end

    it "returns an HTTP Not Allowed responses for PATCH requests by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "PATCH",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::Base.new(request)
      response = view.dispatch
      response.status.should eq 405
    end

    it "returns an HTTP Not Allowed responses for DELETE requests by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "DELETE",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::Base.new(request)
      response = view.dispatch
      response.status.should eq 405
    end

    it "returns an HTTP Not Allowed responses for HEAD requests by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "HEAD",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::Base.new(request)
      response = view.dispatch
      response.status.should eq 405
    end

    it "returns an HTTP Not Allowed responses for TRACE requests by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "TRACE",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::Base.new(request)
      response = view.dispatch
      response.status.should eq 405
    end

    it "returns a 200 OK response containing alloed method names for OPTIONS requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "OPTIONS",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view_1 = Marten::Views::Base.new(request)
      response_1 = view_1.dispatch
      response_1.status.should eq 200
      response_1.headers["Allow"].should eq Marten::Views::Base.http_method_names.join(", ") { |m| m.upcase }
      response_1.headers["Content-Length"].should eq "0"

      view_2 = Marten::Views::BaseSpec::Test1View.new(request)
      response_2 = view_2.dispatch
      response_2.status.should eq 200
      response_2.headers["Allow"].should eq "GET, POST, OPTIONS"
      response_2.headers["Content-Length"].should eq "0"
    end

    it "returns the response for GET request when handling HEAD requests if the head method is not overriden" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "HEAD",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::Test3View.new(request)
      response = view.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "It works!"
    end

    it "is able to process GET requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::Test4View.new(request)
      response = view.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "GET processed"
    end

    it "is able to process POST requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::Test4View.new(request)
      response = view.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "POST processed"
    end

    it "is able to process PUT requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "PUT",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::Test4View.new(request)
      response = view.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "PUT processed"
    end

    it "is able to process PATCH requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "PATCH",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::Test4View.new(request)
      response = view.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "PATCH processed"
    end

    it "is able to process DELETE requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "DELETE",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::Test4View.new(request)
      response = view.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "DELETE processed"
    end

    it "is able to process HEAD requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "HEAD",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::Test4View.new(request)
      response = view.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "HEAD processed"
    end

    it "is able to process OPTIONS requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "OPTIONS",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::Test4View.new(request)
      response = view.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "OPTIONS processed"
    end

    it "is able to process TRACE requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "TRACE",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::Test4View.new(request)
      response = view.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "TRACE processed"
    end

    it "returns an HTTP Not Allowed responses for if the method is not handled by the view" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "PATCH",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::BaseSpec::Test1View.new(request)
      response = view.dispatch
      response.status.should eq 405
    end
  end

  describe "#head" do
    it "returns an empty HTTP response associated with a specific status code" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::BaseSpec::Test1View.new(request)

      response_1 = view.head(404)
      response_1.content.should be_empty
      response_1.content_type.should be_empty
      response_1.status.should eq 404

      response_2 = view.head(403)
      response_2.content.should be_empty
      response_2.content_type.should be_empty
      response_2.status.should eq 403
    end
  end

  describe "#process_dispatch" do
    it "runs before_dispatch and after_dispatch callbacks as expected" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::TestViewWithCallbacks.new(request)

      view.foo.should be_nil
      view.bar.should be_nil

      view.process_dispatch

      view.foo.should eq "set_foo"
      view.bar.should eq "set_bar"
    end

    it "returns the expected dispatch response if dispatch callbacks don't return custom responses" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::TestViewWithCallbacks.new(request)

      response = view.process_dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "Regular response"
    end

    it "returns any early response returned by the before_dispatch callbacks" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::TestViewWithBeforeDispatchResponse.new(request)

      response = view.process_dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "before_dispatch response"
    end

    it "returns any overridden response returned by the after_dispatch callbacks" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::TestViewWithAfterDispatchResponse.new(request)

      response = view.process_dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "after_dispatch response"
    end

    it "sets the returned HTTP response as expected" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::TestViewWithAfterDispatchResponse.new(request)
      view.process_dispatch

      view.response!.status.should eq 200
      view.response!.content_type.should eq "text/plain"
      view.response!.content.should eq "after_dispatch response"
    end
  end

  describe "#response" do
    it "returns nil if the view was not dispatched yet" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::TestViewWithAfterDispatchResponse.new(request)

      view.response.should be_nil
    end

    it "returns the response if the view was dispatched" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::TestViewWithAfterDispatchResponse.new(request)
      view.process_dispatch

      view.response.not_nil!.status.should eq 200
      view.response.not_nil!.content_type.should eq "text/plain"
      view.response.not_nil!.content.should eq "after_dispatch response"
    end
  end

  describe "#response!" do
    it "raise NilAssertionError if the view was not dispatched yet" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::TestViewWithAfterDispatchResponse.new(request)

      expect_raises(NilAssertionError) do
        view.response!
      end
    end

    it "returns the response if the view was dispatched" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::BaseSpec::TestViewWithAfterDispatchResponse.new(request)
      view.process_dispatch

      view.response!.status.should eq 200
      view.response!.content_type.should eq "text/plain"
      view.response!.content.should eq "after_dispatch response"
    end
  end

  describe "#reverse" do
    it "provides a shortcut allowing to perform route lookups" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view_1 = Marten::Views::BaseSpec::Test5View.new(request)
      response_1 = view_1.dispatch
      response_1.status.should eq 200
      response_1.content.should eq Marten.routes.reverse("dummy_with_id", id: 42)

      view_2 = Marten::Views::BaseSpec::Test5View.new(request)
      response_2 = view_2.dispatch
      response_2.status.should eq 200
      response_2.content.should eq Marten.routes.reverse("dummy_with_id", {"id" => 42})
    end
  end

  describe "#respond" do
    it "returns an HTTP response with an associated content and content type" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::BaseSpec::Test1View.new(request)

      response = view.respond(content: "hello world!", content_type: "text/plain")
      response.content.should eq "hello world!"
      response.content_type.should eq "text/plain"
      response.status.should eq 200
    end

    it "returns an HTTP response with an associated status" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::BaseSpec::Test1View.new(request)

      response = view.respond(content: "unauthorized!", content_type: "text/plain", status: 401)
      response.content.should eq "unauthorized!"
      response.content_type.should eq "text/plain"
      response.status.should eq 401
    end
  end
end

module Marten::Views::BaseSpec
  class Test1View < Marten::Views::Base
    http_method_names "get", "post", "options"
  end

  class Test2View < Marten::Views::Base
    http_method_names :post, :put
  end

  class Test3View < Marten::Views::Base
    http_method_names :get, :head

    def get
      Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
    end
  end

  class Test4View < Marten::Views::Base
    def get
      Marten::HTTP::Response.new("GET processed", content_type: "text/plain", status: 200)
    end

    def post
      Marten::HTTP::Response.new("POST processed", content_type: "text/plain", status: 200)
    end

    def put
      Marten::HTTP::Response.new("PUT processed", content_type: "text/plain", status: 200)
    end

    def patch
      Marten::HTTP::Response.new("PATCH processed", content_type: "text/plain", status: 200)
    end

    def delete
      Marten::HTTP::Response.new("DELETE processed", content_type: "text/plain", status: 200)
    end

    def head
      Marten::HTTP::Response.new("HEAD processed", content_type: "text/plain", status: 200)
    end

    def options
      Marten::HTTP::Response.new("OPTIONS processed", content_type: "text/plain", status: 200)
    end

    def trace
      Marten::HTTP::Response.new("TRACE processed", content_type: "text/plain", status: 200)
    end
  end

  class Test5View < Marten::Views::Base
    http_method_names :get, :head

    def get
      Marten::HTTP::Response.new(reverse("dummy_with_id", id: 42), content_type: "text/plain", status: 200)
    end
  end

  class Test6View < Marten::Views::Base
    http_method_names :get, :head

    def get
      Marten::HTTP::Response.new(reverse("dummy_with_id", {"id" => 10}), content_type: "text/plain", status: 200)
    end
  end

  class TestViewWithCallbacks < Marten::Views::Base
    property foo : String? = nil
    property bar : String? = nil

    before_dispatch :set_foo
    after_dispatch :set_bar

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class TestViewWithBeforeDispatchResponse < Marten::Views::Base
    before_dispatch :return_before_dispatch_response

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def return_before_dispatch_response
      Marten::HTTP::Response.new("before_dispatch response", content_type: "text/plain", status: 200)
    end
  end

  class TestViewWithAfterDispatchResponse < Marten::Views::Base
    before_dispatch :return_after_dispatch_response

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def return_after_dispatch_response
      Marten::HTTP::Response.new("after_dispatch response", content_type: "text/plain", status: 200)
    end
  end
end
