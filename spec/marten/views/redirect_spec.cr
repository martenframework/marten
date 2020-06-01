require "./spec_helper"

describe Marten::Views::Redirect do
  describe "::forward_query_string" do
    it "returns false by default" do
      Marten::Views::Redirect.forward_query_string.should be_false
    end

    it "returns true if explicitely set" do
      Marten::Views::RedirectSpec::ViewWithQueryStringForwardingEnabled.forward_query_string.should be_true
    end
  end

  describe "::forward_query_string(v)" do
    it "allows to activate or deactivate query string forwarding for the redirection" do
      Marten::Views::RedirectSpec::ViewWithQueryStringForwardingEnabled.forward_query_string.should be_true
      Marten::Views::RedirectSpec::ViewWithQueryStringForwardingDisabled.forward_query_string.should be_false
    end
  end

  describe "::permanent" do
    it "returns false by default" do
      Marten::Views::Redirect.permanent.should be_false
    end

    it "returns true if explicitely set" do
      Marten::Views::RedirectSpec::PermanentStaticRedirect.permanent.should be_true
    end
  end

  describe "::permanent(v)" do
    it "allows to activate or deactivate permanent redirections" do
      Marten::Views::RedirectSpec::PermanentStaticRedirect.permanent.should be_true
      Marten::Views::RedirectSpec::TemporaryStaticRedirect.permanent.should be_false
    end
  end

  describe "::route_name" do
    it "returns nil by default" do
      Marten::Views::Redirect.route_name.should be_nil
    end

    it "returns the route name if explicitely set" do
      Marten::Views::RedirectSpec::TemporaryDynamicRedirect.route_name.should eq "dummy"
    end
  end

  describe "::route_name(v)" do
    it "allows to set the route name used to perform a lookup when generating the redirect URL" do
      Marten::Views::RedirectSpec::TemporaryDynamicRedirect.route_name.should eq "dummy"
    end
  end

  describe "::url" do
    it "returns nil by default" do
      Marten::Views::Redirect.url.should be_nil
    end

    it "returns the static URL to redirect to if explicitely set" do
      Marten::Views::RedirectSpec::TemporaryStaticRedirect.url.should eq "https://example.com"
    end
  end

  describe "::url(v)" do
    it "allows to set the static URL to redirect to" do
      Marten::Views::RedirectSpec::TemporaryStaticRedirect.url.should eq "https://example.com"
    end
  end

  describe "#get" do
    it "returns an HTTP Gone response if no redirect URL is configured" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      view = Marten::Views::RedirectSpec::UselessRedirect.new(request)
      response = view.dispatch
      response.status.should eq 410
    end

    it "returns the expected HTTP response in case of a temporary redirect involving a static URL" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      view = Marten::Views::RedirectSpec::TemporaryStaticRedirect.new(request)
      response = view.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com"
    end

    it "returns the expected HTTP response in case of a permanent redirect involving a static URL" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      view = Marten::Views::RedirectSpec::PermanentStaticRedirect.new(request)
      response = view.dispatch
      response.status.should eq 301
      response.headers["Location"].should eq "https://example.com"
    end

    it "returns the expected HTTP response in case of a temporary redirect involving a dynamic URL" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      view = Marten::Views::RedirectSpec::TemporaryDynamicRedirect.new(request)
      response = view.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("dummy")
    end

    it "returns the expected HTTP response in case of a permanent redirect involving a dynamic URL" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      view = Marten::Views::RedirectSpec::PermanentDynamicRedirect.new(request)
      response = view.dispatch
      response.status.should eq 301
      response.headers["Location"].should eq Marten.routes.reverse("dummy")
    end

    it "makes use of the view params to perform the lookup of the dynamic redirect route" do
      request = Marten::HTTP::Request.new(::HTTP::Request.new(method: "GET", resource: "", headers: HTTP::Headers.new))
      view = Marten::Views::RedirectSpec::DynamicRedirectWithParams.new(
        request,
        Hash(String, Marten::Routing::Parameter::Types){ "id" => 42 }
      )
      response = view.dispatch
      response.status.should eq 302
      response.headers["Location"].should eq Marten.routes.reverse("dummy_with_id", id: 42)
    end
  end
end

module Marten::Views::RedirectSpec
  class ViewWithQueryStringForwardingEnabled < Marten::Views::Redirect
    forward_query_string true
    url "https://example.com"
  end

  class ViewWithQueryStringForwardingDisabled < Marten::Views::Redirect
    forward_query_string false
    url "https://example.com"
  end

  class PermanentStaticRedirect < Marten::Views::Redirect
    permanent true
    url "https://example.com"
  end

  class TemporaryStaticRedirect < Marten::Views::Redirect
    permanent false
    url "https://example.com"
  end

  class PermanentDynamicRedirect < Marten::Views::Redirect
    permanent true
    route_name "dummy"
  end

  class TemporaryDynamicRedirect < Marten::Views::Redirect
    route_name "dummy"
  end

  class DynamicRedirectWithParams < Marten::Views::Redirect
    route_name "dummy_with_id"
  end

  class UselessRedirect < Marten::Views::Redirect
  end
end
