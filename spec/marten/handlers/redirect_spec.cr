require "./spec_helper"

describe Marten::Handlers::Redirect do
  describe "::forward_query_string?" do
    it "returns false by default" do
      Marten::Handlers::Redirect.forward_query_string?.should be_false
    end

    it "returns true if explicitely set" do
      Marten::Handlers::RedirectSpec::HandlerWithQueryStringForwardingEnabled.forward_query_string?.should be_true
    end
  end

  describe "::forward_query_string(v)" do
    it "allows to activate or deactivate query string forwarding for the redirection" do
      Marten::Handlers::RedirectSpec::HandlerWithQueryStringForwardingEnabled.forward_query_string?.should be_true
      Marten::Handlers::RedirectSpec::HandlerWithQueryStringForwardingDisabled.forward_query_string?.should be_false
    end
  end

  describe "::permanent" do
    it "returns false by default" do
      Marten::Handlers::Redirect.permanent?.should be_false
    end

    it "returns true if explicitely set" do
      Marten::Handlers::RedirectSpec::PermanentStaticRedirect.permanent?.should be_true
    end
  end

  describe "::permanent(v)" do
    it "allows to activate or deactivate permanent redirections" do
      Marten::Handlers::RedirectSpec::PermanentStaticRedirect.permanent?.should be_true
      Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.permanent?.should be_false
    end
  end

  describe "::route_name" do
    it "returns nil by default" do
      Marten::Handlers::Redirect.route_name.should be_nil
    end

    it "returns the route name if explicitely set" do
      Marten::Handlers::RedirectSpec::TemporaryDynamicRedirect.route_name.should eq "dummy"
    end
  end

  describe "::route_name(v)" do
    it "allows to set the route name used to perform a lookup when generating the redirect URL" do
      Marten::Handlers::RedirectSpec::TemporaryDynamicRedirect.route_name.should eq "dummy"
    end
  end

  describe "::url" do
    it "returns nil by default" do
      Marten::Handlers::Redirect.url.should be_nil
    end

    it "returns the static URL to redirect to if explicitely set" do
      Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.url.should eq "https://example.com"
    end
  end

  describe "::url(v)" do
    it "allows to set the static URL to redirect to" do
      Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.url.should eq "https://example.com"
    end
  end

  describe "#get" do
    it "returns an HTTP Gone response if no redirect URL is configured" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      handler = Marten::Handlers::RedirectSpec::UselessRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 410
    end

    it "returns the expected HTTP response in case of a temporary redirect involving a static URL" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      handler = Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com"
    end

    it "returns the expected HTTP response in case of a permanent redirect involving a static URL" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      handler = Marten::Handlers::RedirectSpec::PermanentStaticRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 301
      response.headers["Location"].should eq "https://example.com"
    end

    it "returns the expected HTTP response in case of a temporary redirect involving a dynamic URL" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      handler = Marten::Handlers::RedirectSpec::TemporaryDynamicRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("dummy")
    end

    it "returns the expected HTTP response in case of a permanent redirect involving a dynamic URL" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      handler = Marten::Handlers::RedirectSpec::PermanentDynamicRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 301
      response.headers["Location"].should eq Marten.routes.reverse("dummy")
    end

    it "makes use of the handler params to perform the lookup of the dynamic redirect route" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      handler = Marten::Handlers::RedirectSpec::DynamicRedirectWithParams.new(
        request,
        Marten::Routing::MatchParameters{"id" => 42}
      )
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("dummy_with_id", id: 42)
    end

    it "properly forwards query params if the corresponding option is enabled" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers.new
        )
      )
      handler = Marten::Handlers::RedirectSpec::HandlerWithQueryStringForwardingEnabled.new(
        request,
        Marten::Routing::MatchParameters{"id" => 42}
      )
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com?foo=bar&foo=baz&xyz=test"
    end
  end

  describe "#head" do
    it "produces the same behaviour as GET requests" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "HEAD", resource: "", headers: HTTP::Headers.new))
      handler = Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com"
    end
  end

  describe "#post" do
    it "produces the same behaviour as GET requests" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "POST", resource: "", headers: HTTP::Headers.new))
      handler = Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com"
    end
  end

  describe "#options" do
    it "produces the same behaviour as GET requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "OPTIONS", resource: "", headers: HTTP::Headers.new)
      )
      handler = Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com"
    end
  end

  describe "#delete" do
    it "produces the same behaviour as GET requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "DELETE", resource: "", headers: HTTP::Headers.new)
      )
      handler = Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com"
    end
  end

  describe "#put" do
    it "produces the same behaviour as GET requests" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "PUT", resource: "", headers: HTTP::Headers.new))
      handler = Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com"
    end
  end

  describe "#patch" do
    it "produces the same behaviour as GET requests" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(method: "PATCH", resource: "", headers: HTTP::Headers.new)
      )
      handler = Marten::Handlers::RedirectSpec::TemporaryStaticRedirect.new(request)
      response = handler.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com"
    end
  end
end

module Marten::Handlers::RedirectSpec
  class HandlerWithQueryStringForwardingEnabled < Marten::Handlers::Redirect
    forward_query_string true
    url "https://example.com"
  end

  class HandlerWithQueryStringForwardingDisabled < Marten::Handlers::Redirect
    forward_query_string false
    url "https://example.com"
  end

  class PermanentStaticRedirect < Marten::Handlers::Redirect
    permanent true
    url "https://example.com"
  end

  class TemporaryStaticRedirect < Marten::Handlers::Redirect
    permanent false
    url "https://example.com"
  end

  class PermanentDynamicRedirect < Marten::Handlers::Redirect
    permanent true
    route_name "dummy"
  end

  class TemporaryDynamicRedirect < Marten::Handlers::Redirect
    route_name "dummy"
  end

  class DynamicRedirectWithParams < Marten::Handlers::Redirect
    route_name "dummy_with_id"
  end

  class UselessRedirect < Marten::Handlers::Redirect
  end
end
