require "./spec_helper"

describe Marten::Handlers::CrossOriginOpenerPolicy do
  describe "::cross_origin_opener_policy" do
    it "allows to define a custom Cross-Origin-Opener-Policy value for a handler class" do
      Marten::Handlers::CrossOriginOpenerPolicySpec::HandlerWithCustomPolicy
        .cross_origin_opener_policy
        .should eq "same-origin-allow-popups"
    end

    it "normalizes underscored symbol values to header values" do
      Marten::Handlers::CrossOriginOpenerPolicySpec::HandlerWithSymbolPolicy
        .cross_origin_opener_policy
        .should eq "unsafe-none"
    end

    it "clears the exemption when a custom policy value is defined" do
      Marten::Handlers::CrossOriginOpenerPolicySpec::HandlerWithCustomPolicy
        .exempt_from_cross_origin_opener_policy?
        .should be_false
    end
  end

  describe "::exempt_from_cross_origin_opener_policy" do
    it "allows to mark a handler class as exempted from using the Cross-Origin-Opener-Policy header" do
      Marten::Handlers::CrossOriginOpenerPolicySpec::ExemptedHandler
        .exempt_from_cross_origin_opener_policy?
        .should be_true
    end

    it "allows to mark a handler class as non-exempted from using the Cross-Origin-Opener-Policy header" do
      Marten::Handlers::CrossOriginOpenerPolicySpec::NonExemptedHandler
        .exempt_from_cross_origin_opener_policy?
        .should be_false
    end

    it "resets the custom policy value if one was set" do
      Marten::Handlers::CrossOriginOpenerPolicySpec::ExemptedHandler.cross_origin_opener_policy.should be_nil
    end
  end

  describe "::exempt_from_cross_origin_opener_policy?" do
    it "returns true if the handler class is exempted from using the Cross-Origin-Opener-Policy header" do
      Marten::Handlers::CrossOriginOpenerPolicySpec::ExemptedHandler
        .exempt_from_cross_origin_opener_policy?
        .should be_true
    end

    it "returns false if the handler class is not exempted from using the Cross-Origin-Opener-Policy header" do
      Marten::Handlers::CrossOriginOpenerPolicySpec::NonExemptedHandler
        .exempt_from_cross_origin_opener_policy?
        .should be_false
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

      handler = Marten::Handlers::CrossOriginOpenerPolicySpec::ExemptedHandler.new(request)
      response = handler.process_dispatch

      response.headers[:"Cross-Origin-Opener-Policy-Exempt"].should eq "true"
      response.headers.has_key?(:"Cross-Origin-Opener-Policy").should be_false
    end

    it "does not insert a temporary header in the response if the handler is not exempted" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      handler = Marten::Handlers::CrossOriginOpenerPolicySpec::NonExemptedHandler.new(request)
      response = handler.process_dispatch

      response.headers.has_key?(:"Cross-Origin-Opener-Policy-Exempt").should be_false
    end

    it "inserts the custom Cross-Origin-Opener-Policy header value when one is defined" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      handler = Marten::Handlers::CrossOriginOpenerPolicySpec::HandlerWithCustomPolicy.new(request)
      response = handler.process_dispatch

      response.headers[:"Cross-Origin-Opener-Policy"].should eq "same-origin-allow-popups"
    end
  end
end

module Marten::Handlers::CrossOriginOpenerPolicySpec
  class ExemptedHandler < Marten::Handler
    include Marten::Handlers::CrossOriginOpenerPolicy

    cross_origin_opener_policy "same-origin-allow-popups"
    exempt_from_cross_origin_opener_policy true
  end

  class NonExemptedHandler < Marten::Handler
    include Marten::Handlers::CrossOriginOpenerPolicy

    exempt_from_cross_origin_opener_policy false
  end

  class HandlerWithCustomPolicy < Marten::Handler
    cross_origin_opener_policy "same-origin-allow-popups"
  end

  class HandlerWithSymbolPolicy < Marten::Handler
    cross_origin_opener_policy :unsafe_none
  end
end
