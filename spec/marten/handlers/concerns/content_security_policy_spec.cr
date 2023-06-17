require "./spec_helper"

describe Marten::Handlers::ContentSecurityPolicy do
  describe "::exempt_from_content_security_policy" do
    it "allows to mark a handler class as exempted from using the Content-Security-Policy header" do
      Marten::Handlers::ContentSecurityPolicySpec::ExemptedHandler.exempt_from_content_security_policy?.should be_true
    end

    it "allows to mark a handler class as non-exempted from using the Content-Security-Policy header" do
      Marten::Handlers::ContentSecurityPolicySpec::NonExemptedHandler.exempt_from_content_security_policy?.should(
        be_false
      )
    end

    it "resets the content security policy block if one was set" do
      Marten::Handlers::ContentSecurityPolicySpec::ExemptedHandler.content_security_policy_block.should be_nil
    end
  end

  describe "::exempt_from_content_security_policy?" do
    it "returns true if the handler class is exempted from using the Content-Security-Policy header" do
      Marten::Handlers::ContentSecurityPolicySpec::ExemptedHandler.exempt_from_content_security_policy?.should be_true
    end

    it "returns false if the handler class is not exempted from using the Content-Security-Policy header" do
      Marten::Handlers::ContentSecurityPolicySpec::NonExemptedHandler.exempt_from_content_security_policy?.should(
        be_false
      )
    end
  end

  describe "#process_dispatch" do
    it "inserts a temporary header in the response if the handler is exempted" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      handler = Marten::Handlers::ContentSecurityPolicySpec::ExemptedHandler.new(request)
      response = handler.process_dispatch

      request.content_security_policy.should be_nil
      response.headers[:"Content-Security-Policy-Exempt"].should eq "true"
    end

    it "does not insert a temporary header in the response if the handler is not exempted" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      handler = Marten::Handlers::ContentSecurityPolicySpec::NonExemptedHandler.new(request)
      response = handler.process_dispatch

      request.content_security_policy.should be_nil
      response.headers.has_key?(:"Content-Security-Policy-Exempt").should be_false
    end

    it "overrides the request's Content-Security-Policy object when a custom CSP object is defined" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      handler = Marten::Handlers::ContentSecurityPolicySpec::HandlerWithCustomPolicy.new(request)
      handler.process_dispatch

      request.content_security_policy.should be_a Marten::HTTP::ContentSecurityPolicy
      csp = request.content_security_policy.as(Marten::HTTP::ContentSecurityPolicy)
      csp.directives["default-src"].should eq ["'self'", "example.com"]
    end

    it "overrides and clones the request's Content-Security-Policy object when a custom CSP object is defined" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      original_csp = Marten::HTTP::ContentSecurityPolicy.new
      original_csp.frame_src = :self

      request.content_security_policy = original_csp

      handler = Marten::Handlers::ContentSecurityPolicySpec::HandlerWithCustomPolicy.new(request)
      handler.process_dispatch

      request.content_security_policy.should be_a Marten::HTTP::ContentSecurityPolicy
      request.content_security_policy.try(&.object_id).should_not eq original_csp.object_id

      csp = request.content_security_policy.as(Marten::HTTP::ContentSecurityPolicy)
      csp.directives["default-src"].should eq ["'self'", "example.com"]
      csp.directives["frame-src"].should eq ["'self'"]
    end
  end
end

module Marten::Handlers::ContentSecurityPolicySpec
  class ExemptedHandler < Marten::Handler
    include Marten::Handlers::ContentSecurityPolicy

    exempt_from_content_security_policy true
  end

  class NonExemptedHandler < Marten::Handler
    include Marten::Handlers::ContentSecurityPolicy

    content_security_policy do |csp|
      csp.default_src = {:self, "example.com"}
    end

    exempt_from_content_security_policy false
  end

  class HandlerWithCustomPolicy < Marten::Handler
    content_security_policy do |csp|
      csp.default_src = {:self, "example.com"}
    end
  end
end
