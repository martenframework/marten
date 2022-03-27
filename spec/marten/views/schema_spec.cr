require "./spec_helper"
require "./schema_spec/**"

describe Marten::Views::Schema do
  describe "::schema" do
    it "returns the configured schema class" do
      Marten::Views::SchemaSpec::TestView.schema.should eq Marten::Views::SchemaSpec::TestSchema
    end

    it "returns nil by default" do
      Marten::Views::SchemaSpec::TestViewWithoutConfiguration.schema.should be_nil
    end
  end

  describe "::success_route_name" do
    it "returns the configured success URL" do
      Marten::Views::SchemaSpec::TestView.success_route_name.should eq "dummy"
    end

    it "returns nil by default" do
      Marten::Views::SchemaSpec::TestViewWithoutConfiguration.success_route_name.should be_nil
    end
  end

  describe "::success_url" do
    it "returns the configured success URL" do
      Marten::Views::SchemaSpec::TestViewWithSuccessUrl.success_url.should eq "https://example.com"
    end

    it "returns nil by default" do
      Marten::Views::SchemaSpec::TestViewWithoutConfiguration.success_url.should be_nil
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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      view.context["schema"].should be_a Marten::Views::SchemaSpec::TestSchema
      view.context["schema"]["foo"].value.should be_nil
      view.context["schema"]["bar"].value.should be_nil
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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      view.context["schema"].should be_a Marten::Views::SchemaSpec::TestSchema
      view.context["schema"]["foo"].value.should eq "123"
      view.context["schema"]["bar"].value.should eq "456"
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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      response = view.post

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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      response = view.post

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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      view.schema.valid?
      response = view.process_invalid_schema

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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      view.schema.valid?
      response = view.process_valid_schema

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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      response = view.put

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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      response = view.put

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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      view.schema.should be_a Marten::Views::SchemaSpec::TestSchema
      view.schema["foo"].value.should eq "123"
      view.schema["bar"].value.should eq "456"
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
      view = Marten::Views::SchemaSpec::TestView.new(request)

      view.schema_class.should eq Marten::Views::SchemaSpec::TestSchema
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
      view = Marten::Views::SchemaSpec::TestViewWithoutConfiguration.new(request)

      expect_raises(Marten::Views::Errors::ImproperlyConfigured) { view.schema_class }
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
      view = Marten::Views::SchemaSpec::TestViewWithSuccessUrl.new(request)

      view.success_url.should eq "https://example.com"
    end

    it "returns the resolved success route if configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::SchemaSpec::TestView.new(request)

      view.success_url.should eq Marten.routes.reverse("dummy")
    end

    it "raises if no success URL is configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::SchemaSpec::TestViewWithoutConfiguration.new(request)

      expect_raises(Marten::Views::Errors::ImproperlyConfigured) { view.success_url }
    end
  end
end

module Marten::Views::SchemaSpec
  class TestView < Marten::Views::Schema
    schema TestSchema
    success_route_name "dummy"
    template_name "specs/views/schema/test.html"
  end

  class TestViewWithSuccessUrl < Marten::Views::Schema
    schema TestSchema
    success_url "https://example.com"
  end

  class TestViewWithoutConfiguration < Marten::Views::Schema
  end
end
