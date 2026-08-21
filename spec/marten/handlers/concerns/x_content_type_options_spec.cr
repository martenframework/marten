require "./spec_helper"

describe Marten::Handlers::XContentTypeOptions do
  describe "::exempt_from_x_content_type_options" do
    it "allows to mark a handler class as exempted from using the X-Content-Type-Options header" do
      Marten::Handlers::XContentTypeOptionsSpec::ExemptedHandler.exempt_from_x_content_type_options?.should be_true
    end

    it "allows to mark a handler class as non-exempted from using the X-Content-Type-Options header" do
      Marten::Handlers::XContentTypeOptionsSpec::NonExemptedHandler.exempt_from_x_content_type_options?.should be_false
    end
  end

  describe "::exempt_from_x_content_type_options?" do
    it "returns true if the handler class is exempted from using the X-Content-Type-Options header" do
      Marten::Handlers::XContentTypeOptionsSpec::ExemptedHandler.exempt_from_x_content_type_options?.should be_true
    end

    it "returns false if the handler class is not exempted from using the X-Content-Type-Options header" do
      Marten::Handlers::XContentTypeOptionsSpec::NonExemptedHandler.exempt_from_x_content_type_options?.should be_false
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

      handler = Marten::Handlers::XContentTypeOptionsSpec::ExemptedHandler.new(request)
      response = handler.process_dispatch

      response.headers[:"X-Content-Type-Options-Exempt"].should eq "true"
    end

    it "does not insert a temporary header in the response if the handler is not exempted" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        )
      )

      handler = Marten::Handlers::XContentTypeOptionsSpec::NonExemptedHandler.new(request)
      response = handler.process_dispatch

      response.headers.has_key?(:"X-Content-Type-Options-Exempt").should be_false
    end
  end
end

module Marten::Handlers::XContentTypeOptionsSpec
  class ExemptedHandler < Marten::Handler
    include Marten::Handlers::XContentTypeOptions

    exempt_from_x_content_type_options true
  end

  class NonExemptedHandler < Marten::Handler
    include Marten::Handlers::XContentTypeOptions

    exempt_from_x_content_type_options false
  end
end
