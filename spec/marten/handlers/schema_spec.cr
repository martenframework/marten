require "./spec_helper"
require "./schema_spec/**"

describe Marten::Handlers::Schema do
  describe "::success_route_name" do
    it "returns the configured success URL" do
      Marten::Handlers::SchemaSpec::TestHandler.success_route_name.should eq "dummy"
    end

    it "returns nil by default" do
      Marten::Handlers::SchemaSpec::TestHandlerWithoutConfiguration.success_route_name.should be_nil
    end
  end

  describe "::success_url" do
    it "returns the configured success URL" do
      Marten::Handlers::SchemaSpec::TestHandlerWithSuccessUrl.success_url.should eq "https://example.com"
    end

    it "returns nil by default" do
      Marten::Handlers::SchemaSpec::TestHandlerWithoutConfiguration.success_url.should be_nil
    end
  end

  describe "#context" do
    it "includes the schema instance without data if the request does not provide data" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.context["schema"].raw.should be_a Marten::Handlers::SchemaSpec::TestSchema
      schema = handler.context["schema"].raw.as(Marten::Schema)
      schema["foo"].value.should be_nil
      schema["bar"].value.should be_nil
    end

    it "includes the schema instance with data if the request provides data" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.context["schema"].raw.should be_a Marten::Handlers::SchemaSpec::TestSchema
      schema = handler.context["schema"].raw.as(Marten::Schema)
      schema["foo"].value.should eq "123"
      schema["bar"].value.should eq "456"
    end
  end

  describe "#post" do
    it "returns the expected redirect response if the schema is valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      response = handler.post

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")
    end

    it "re-renders the template if the schema is not valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      response = handler.post

      response.should be_a Marten::HTTP::Response
      response.status.should eq 200
      response.content.includes?("Schema is invalid").should be_true
    end
  end

  describe "#process_invalid_schema" do
    it "re-renders the template" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.schema.valid?
      response = handler.process_invalid_schema

      response.should be_a Marten::HTTP::Response
      response.status.should eq 200
      response.content.includes?("Schema is invalid").should be_true
    end
  end

  describe "#process_valid_schema" do
    it "returns the expected redirect response" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.schema.valid?
      response = handler.process_valid_schema

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")
    end
  end

  describe "#put" do
    it "returns the expected redirect response if the schema is valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      response = handler.put

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")
    end

    it "re-renders the template if the schema is not valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      response = handler.put

      response.should be_a Marten::HTTP::Response
      response.status.should eq 200
      response.content.includes?("Schema is invalid").should be_true
    end
  end

  describe "#schema" do
    it "returns the schema initialized with the request data" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.schema.should be_a Marten::Handlers::SchemaSpec::TestSchema
      handler.schema["foo"].value.should eq "123"
      handler.schema["bar"].value.should eq "456"
    end
  end

  describe "#schema_class" do
    it "returns the configured schema class" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.schema_class.should eq Marten::Handlers::SchemaSpec::TestSchema
    end

    it "raises if no schema class is configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandlerWithoutConfiguration.new(request)

      expect_raises(Marten::Handlers::Errors::ImproperlyConfigured) { handler.schema_class }
    end
  end

  describe "#success_url" do
    it "returns the raw success URL if configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandlerWithSuccessUrl.new(request)

      handler.success_url.should eq "https://example.com"
    end

    it "returns the resolved success route if configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.success_url.should eq Marten.routes.reverse("dummy")
    end

    it "raises if no success URL is configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandlerWithoutConfiguration.new(request)

      expect_raises(Marten::Handlers::Errors::ImproperlyConfigured) { handler.success_url }
    end
  end
end

module Marten::Handlers::SchemaSpec
  class TestHandler < Marten::Handlers::Schema
    schema TestSchema
    success_route_name "dummy"
    template_name "specs/handlers/schema/test.html"
  end

  class TestHandlerWithSuccessUrl < Marten::Handlers::Schema
    schema TestSchema
    success_url "https://example.com"
  end

  class TestHandlerWithoutConfiguration < Marten::Handlers::Schema
  end
end
