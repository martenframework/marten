require "./spec_helper"

describe Marten::Handlers::Base do
  describe "::new" do
    it "allows to initialize a handler instance from an HTTP request object" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::Base.new(request)
      handler.nil?.should be_false
      handler.params.empty?.should be_true
    end

    it "allows to initialize a handler instance from an HTTP request object and a hash of routing parameters" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      params_1 = Marten::Routing::MatchParameters{"id" => 42}
      handler_1 = Marten::Handlers::Base.new(request, params_1)
      handler_1.params.should eq({"id" => 42})

      params_2 = Marten::Routing::MatchParameters{"slug" => "my-slug"}
      handler_2 = Marten::Handlers::Base.new(request, params_2)
      handler_2.params.should eq({"slug" => "my-slug"})

      params_3 = Marten::Routing::MatchParameters{
        "id" => ::UUID.new("a288e10f-fffe-46d1-b71a-436e9190cdc3"),
      }
      handler_3 = Marten::Handlers::Base.new(request, params_3)
      handler_3.params.should eq({"id" => ::UUID.new("a288e10f-fffe-46d1-b71a-436e9190cdc3")})
    end

    it "allows to initialize a handler instance from an HTTP request object and keyword arguments" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler_1 = Marten::Handlers::Base.new(request, id: 42)
      handler_1.params.should eq({"id" => 42})

      handler_2 = Marten::Handlers::Base.new(request, slug: "my-slug")
      handler_2.params.should eq({"slug" => "my-slug"})

      handler_3 = Marten::Handlers::Base.new(request, id: ::UUID.new("a288e10f-fffe-46d1-b71a-436e9190cdc3"))
      handler_3.params.should eq({"id" => ::UUID.new("a288e10f-fffe-46d1-b71a-436e9190cdc3")})
    end
  end

  describe "::http_method_names" do
    it "returns all the HTTP method names unless explicitely set" do
      Marten::Handlers::Base.http_method_names.should eq %w(get post put patch delete head options trace)
    end

    it "returns the configured HTTP method names if explictely set" do
      Marten::Handlers::BaseSpec::Test1Handler.http_method_names.should eq %w(get post options)
    end
  end

  describe "::http_method_names(*method_names)" do
    it "allows to set the supported HTTP method names using strings" do
      Marten::Handlers::BaseSpec::Test1Handler.http_method_names.should eq %w(get post options)
    end

    it "allows to set the supported HTTP method names using symbols" do
      Marten::Handlers::BaseSpec::Test2Handler.http_method_names.should eq %w(post put)
    end
  end

  describe "#context" do
    it "returns an empty global template context object initialized from configured context producers" do
      previous_context_producers = Marten.templates.context_producers
      Marten.templates.context_producers = [
        Marten::Template::ContextProducer::Request.new,
      ] of Marten::Template::ContextProducer

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "",
        headers: HTTP::Headers{"Host" => "example.com"}
      )
      handler = Marten::Handlers::Base.new(request)

      context = handler.context

      context.should be_a Marten::Template::Context
      context["request"].should eq request

      Marten.templates.context_producers = previous_context_producers
    end

    it "returns a global template context object that is memoized" do
      handler = Marten::Handlers::Base.new(
        Marten::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      context = handler.context

      context.should be_a Marten::Template::Context
      handler.context.object_id.should eq context.object_id
    end
  end

  describe "#request" do
    it "returns the request handled by the handler" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::Base.new(request)
      handler.request.should eq request
    end
  end

  describe "#params" do
    it "returns the routing parameters handled by the handler" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      params = Marten::Routing::MatchParameters{"id" => 42}
      handler = Marten::Handlers::Base.new(request, params)
      handler.params.should eq params
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
      handler = Marten::Handlers::Base.new(request)
      response = handler.dispatch
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
      handler = Marten::Handlers::Base.new(request)
      response = handler.dispatch
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
      handler = Marten::Handlers::Base.new(request)
      response = handler.dispatch
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
      handler = Marten::Handlers::Base.new(request)
      response = handler.dispatch
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
      handler = Marten::Handlers::Base.new(request)
      response = handler.dispatch
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
      handler = Marten::Handlers::Base.new(request)
      response = handler.dispatch
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
      handler = Marten::Handlers::Base.new(request)
      response = handler.dispatch
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

      handler_1 = Marten::Handlers::Base.new(request)
      response_1 = handler_1.dispatch
      response_1.status.should eq 200
      response_1.headers["Allow"].should eq Marten::Handlers::Base.http_method_names.join(", ", &.upcase)
      response_1.headers["Content-Length"].should eq "0"

      handler_2 = Marten::Handlers::BaseSpec::Test1Handler.new(request)
      response_2 = handler_2.dispatch
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

      handler = Marten::Handlers::BaseSpec::Test3Handler.new(request)
      response = handler.dispatch
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

      handler = Marten::Handlers::BaseSpec::Test4Handler.new(request)
      response = handler.dispatch
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

      handler = Marten::Handlers::BaseSpec::Test4Handler.new(request)
      response = handler.dispatch
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

      handler = Marten::Handlers::BaseSpec::Test4Handler.new(request)
      response = handler.dispatch
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

      handler = Marten::Handlers::BaseSpec::Test4Handler.new(request)
      response = handler.dispatch
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

      handler = Marten::Handlers::BaseSpec::Test4Handler.new(request)
      response = handler.dispatch
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

      handler = Marten::Handlers::BaseSpec::Test4Handler.new(request)
      response = handler.dispatch
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

      handler = Marten::Handlers::BaseSpec::Test4Handler.new(request)
      response = handler.dispatch
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

      handler = Marten::Handlers::BaseSpec::Test4Handler.new(request)
      response = handler.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "TRACE processed"
    end

    it "returns an HTTP Not Allowed responses for if the method is not handled by the handler" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "PATCH",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)
      response = handler.dispatch
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
      handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)

      response_1 = handler.head(404)
      response_1.content.should be_empty
      response_1.content_type.should be_empty
      response_1.status.should eq 404

      response_2 = handler.head(403)
      response_2.content.should be_empty
      response_2.content_type.should be_empty
      response_2.status.should eq 403
    end
  end

  describe "#json" do
    context "with a raw JSON string" do
      it "returns the expected HTTP response" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)
        response = handler.json({foo: "bar"}.to_json)

        response.content_type.should eq "application/json"
        response.status.should eq 200
        response.content.should eq({foo: "bar"}.to_json)
      end

      it "allows to customize the status code" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)
        response = handler.json({foo: "bar"}.to_json, status: 404)

        response.content_type.should eq "application/json"
        response.status.should eq 404
        response.content.should eq({foo: "bar"}.to_json)
      end
    end

    context "a serializable object" do
      it "returns the expected HTTP response" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)

        response_1 = handler.json({"foo" => "bar"})
        response_1.content_type.should eq "application/json"
        response_1.status.should eq 200
        response_1.content.should eq({"foo" => "bar"}.to_json)

        response_2 = handler.json({foo: "bar"})
        response_2.content_type.should eq "application/json"
        response_2.status.should eq 200
        response_2.content.should eq({foo: "bar"}.to_json)
      end

      it "allows to customize the status code" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)
        response = handler.json({foo: "bar"}, status: 404)

        response.content_type.should eq "application/json"
        response.status.should eq 404
        response.content.should eq({foo: "bar"}.to_json)
      end
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

      handler = Marten::Handlers::BaseSpec::TestHandlerWithCallbacks.new(request)

      handler.foo.should be_nil
      handler.bar.should be_nil

      handler.process_dispatch

      handler.foo.should eq "set_foo"
      handler.bar.should eq "set_bar"
    end

    it "returns the expected dispatch response if dispatch callbacks don't return custom responses" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::TestHandlerWithCallbacks.new(request)

      response = handler.process_dispatch
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

      handler = Marten::Handlers::BaseSpec::TestHandlerWithBeforeDispatchResponse.new(request)

      response = handler.process_dispatch
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

      handler = Marten::Handlers::BaseSpec::TestHandlerWithAfterDispatchResponse.new(request)

      response = handler.process_dispatch
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

      handler = Marten::Handlers::BaseSpec::TestHandlerWithAfterDispatchResponse.new(request)
      handler.process_dispatch

      handler.response!.status.should eq 200
      handler.response!.content_type.should eq "text/plain"
      handler.response!.content.should eq "after_dispatch response"
    end
  end

  describe "#redirect" do
    it "returns an 302 Found HTTP response for a specific location by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)

      response = handler.redirect("https://example.com")
      response.should be_a Marten::HTTP::Response::Found
      response.headers.should eq(Marten::HTTP::Headers{"Location" => "https://example.com"})
    end

    it "returns an 301 Moved Permanently HTTP response for a specific location if permanent is set to true" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)

      response = handler.redirect("https://example.com", permanent: true)
      response.should be_a Marten::HTTP::Response::MovedPermanently
      response.headers.should eq(Marten::HTTP::Headers{"Location" => "https://example.com"})
    end
  end

  describe "#response" do
    it "returns nil if the handler was not dispatched yet" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::TestHandlerWithAfterDispatchResponse.new(request)

      handler.response.should be_nil
    end

    it "returns the response if the handler was dispatched" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::TestHandlerWithAfterDispatchResponse.new(request)
      handler.process_dispatch

      handler.response.not_nil!.status.should eq 200
      handler.response.not_nil!.content_type.should eq "text/plain"
      handler.response.not_nil!.content.should eq "after_dispatch response"
    end
  end

  describe "#response!" do
    it "raise NilAssertionError if the handler was not dispatched yet" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::TestHandlerWithAfterDispatchResponse.new(request)

      expect_raises(NilAssertionError) do
        handler.response!
      end
    end

    it "returns the response if the handler was dispatched" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::TestHandlerWithAfterDispatchResponse.new(request)
      handler.process_dispatch

      handler.response!.status.should eq 200
      handler.response!.content_type.should eq "text/plain"
      handler.response!.content.should eq "after_dispatch response"
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

      handler_1 = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response_1 = handler_1.dispatch
      response_1.status.should eq 200
      response_1.content.should eq Marten.routes.reverse("dummy_with_id", id: 42)

      handler_2 = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response_2 = handler_2.dispatch
      response_2.status.should eq 200
      response_2.content.should eq Marten.routes.reverse("dummy_with_id", {"id" => 42})
    end
  end

  describe "#render" do
    it "returns an HTTP response containing the template rendered using a specific context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response = handler.render("specs/handlers/base/test.html", context: {name: "John Doe"})

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "is able to render the template using a named tuple context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response = handler.render("specs/handlers/base/test.html", context: {name: "John Doe"})

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "is able to render the template using a hash context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response = handler.render("specs/handlers/base/test.html", context: {"name" => "John Doe"})

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "is able to render the template using the global context" do
      handler = Marten::Handlers::BaseSpec::Test5Handler.new(
        Marten::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler.context["name"] = "John Doe"

      response = handler.render("specs/handlers/base/test.html")

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "is able to render the template using a context object" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response = handler.render(
        "specs/handlers/base/test.html",
        context: Marten::Template::Context{"name" => "John Doe"}
      )

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "includes the handler in the context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response = handler.render("specs/handlers/base/handler.html")

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq HTML.escape(handler.to_s)
    end

    it "allows to specify a specific status code" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response = handler.render("specs/handlers/base/test.html", context: {name: "John Doe"}, status: 404)

      response.status.should eq 404
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "allows to specify a specific status code as symbol" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response = handler.render("specs/handlers/base/test.html", context: {name: "John Doe"}, status: :not_found)

      response.status.should eq 404
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "allows to specify a specific content type" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::Test5Handler.new(request)
      response = handler.render(
        "specs/handlers/base/test.html",
        context: {name: "John Doe"},
        content_type: "text/plain"
      )

      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "runs before_render callbacks as expected" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::TestHandlerWithCallbacks.new(request)

      handler.xyz.should be_nil

      response = handler.render(
        "specs/handlers/base/test.html",
        context: {name: "John Doe"},
        content_type: "text/plain"
      )

      handler.xyz.should eq "set_xyz"

      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "returns the expected response if the before_render callback returns a custom responses" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::TestHandlerWithBeforeRenderResponse.new(request)

      response = handler.render(
        "specs/handlers/base/test.html",
        context: {name: "John Doe"},
        content_type: "text/plain"
      )

      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "before_render response"
    end

    it "returns the expected response if the before_render callback returns a value that is not an HTTP response" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::BaseSpec::TestHandlerWithContextBeforeRenderResponse.new(request)

      response = handler.render(
        "specs/handlers/base/test.html",
        content_type: "text/plain"
      )

      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.strip.should eq "Hello World, John Doe!"
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
      handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)

      response = handler.respond(content: "hello world!", content_type: "text/plain")
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
      handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)

      response = handler.respond(content: "unauthorized!", content_type: "text/plain", status: 401)
      response.content.should eq "unauthorized!"
      response.content_type.should eq "text/plain"
      response.status.should eq 401
    end

    it "returns a streaming HTTP response with an associated content and content type" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)

      response = handler.respond(streamed_content: ["foo", "bar"].each, content_type: "text/csv")

      response.should be_a Marten::HTTP::Response::Streaming
      response = response.as(Marten::HTTP::Response::Streaming)

      response.streamed_content.to_a.should eq ["foo", "bar"]
      response.content_type.should eq "text/csv"
      response.status.should eq 200
    end

    it "returns a streaming HTTP response with an associated status" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::BaseSpec::Test1Handler.new(request)

      response = handler.respond(streamed_content: ["foo", "bar"].each, status: 400)

      response.should be_a Marten::HTTP::Response::Streaming
      response = response.as(Marten::HTTP::Response::Streaming)

      response.streamed_content.to_a.should eq ["foo", "bar"]
      response.content_type.should eq "text/html"
      response.status.should eq 400
    end
  end
end

module Marten::Handlers::BaseSpec
  class Test1Handler < Marten::Handlers::Base
    http_method_names "get", "post", "options"
  end

  class Test2Handler < Marten::Handlers::Base
    http_method_names :post, :put
  end

  class Test3Handler < Marten::Handlers::Base
    http_method_names :get, :head

    def get
      Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
    end
  end

  class Test4Handler < Marten::Handlers::Base
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

  class Test5Handler < Marten::Handlers::Base
    http_method_names :get, :head

    def get
      Marten::HTTP::Response.new(reverse("dummy_with_id", id: 42), content_type: "text/plain", status: 200)
    end
  end

  class Test6Handler < Marten::Handlers::Base
    http_method_names :get, :head

    def get
      Marten::HTTP::Response.new(reverse("dummy_with_id", {"id" => 10}), content_type: "text/plain", status: 200)
    end
  end

  class TestHandlerWithCallbacks < Marten::Handlers::Base
    property foo : String? = nil
    property xyz : String? = nil
    property bar : String? = nil

    before_dispatch :set_foo
    before_render :set_xyz
    after_dispatch :set_bar

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_xyz
      self.xyz = "set_xyz"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class TestHandlerWithBeforeDispatchResponse < Marten::Handlers::Base
    before_dispatch :return_before_dispatch_response

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def return_before_dispatch_response
      Marten::HTTP::Response.new("before_dispatch response", content_type: "text/plain", status: 200)
    end
  end

  class TestHandlerWithBeforeRenderResponse < Marten::Handlers::Base
    before_render :return_before_render_response

    private def return_before_render_response
      Marten::HTTP::Response.new("before_render response", content_type: "text/plain", status: 200)
    end
  end

  class TestHandlerWithContextBeforeRenderResponse < Marten::Handlers::Base
    before_render :add_context_values

    private def add_context_values
      context["name"] = "John Doe"
      "bar"
    end
  end

  class TestHandlerWithAfterDispatchResponse < Marten::Handlers::Base
    before_dispatch :return_after_dispatch_response

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def return_after_dispatch_response
      Marten::HTTP::Response.new("after_dispatch response", content_type: "text/plain", status: 200)
    end
  end
end
