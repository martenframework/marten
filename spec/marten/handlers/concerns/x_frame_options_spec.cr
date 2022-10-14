require "./spec_helper"

describe Marten::Handlers::XFrameOptions do
  describe "::exempt_from_x_frame_options" do
    it "allows to mark a handler class as exempted from using the X-Frame-Options header" do
      Marten::Handlers::XFrameOptionsSpec::ExemptedHandler.exempt_from_x_frame_options?.should be_true
    end

    it "allows to mark a handler class as non-exempted from using the X-Frame-Options header" do
      Marten::Handlers::XFrameOptionsSpec::NonExemptedHandler.exempt_from_x_frame_options?.should be_false
    end
  end

  describe "::exempt_from_x_frame_options?" do
    it "returns true if the handler class is exempted from using the X-Frame-Options header" do
      Marten::Handlers::XFrameOptionsSpec::ExemptedHandler.exempt_from_x_frame_options?.should be_true
    end

    it "returns false if the handler class is not exempted from using the X-Frame-Options header" do
      Marten::Handlers::XFrameOptionsSpec::NonExemptedHandler.exempt_from_x_frame_options?.should be_false
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

      handler = Marten::Handlers::XFrameOptionsSpec::ExemptedHandler.new(request)
      response = handler.process_dispatch

      response.headers[:"X-Frame-Options-Exempt"].should eq "true"
    end

    it "does not insert a temporary header in the response if the handler is not exempted" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      handler = Marten::Handlers::XFrameOptionsSpec::NonExemptedHandler.new(request)
      response = handler.process_dispatch

      response.headers.has_key?(:"X-Frame-Options-Exempt").should be_false
    end
  end
end

module Marten::Handlers::XFrameOptionsSpec
  class ExemptedHandler < Marten::Handler
    include Marten::Handlers::XFrameOptions

    exempt_from_x_frame_options true
  end

  class NonExemptedHandler < Marten::Handler
    include Marten::Handlers::XFrameOptions

    exempt_from_x_frame_options false
  end
end
