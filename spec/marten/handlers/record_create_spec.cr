require "./spec_helper"
require "./record_create_spec/**"

describe Marten::Handlers::RecordCreate do
  with_installed_apps Marten::Handlers::RecordCreateSpec::App

  describe "::model(model)" do
    it "allows to configure the model used when creating the record" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "",
        headers: HTTP::Headers{"Host" => "example.com"}
      )

      Marten::Handlers::RecordCreateSpec::TestHandler.new(request).model.should eq(
        Marten::Handlers::RecordCreateSpec::Tag
      )
    end
  end

  describe "#model" do
    it "returns the configured model class" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::RecordCreateSpec::TestHandler.new(request)

      handler.model.should eq Marten::Handlers::RecordCreateSpec::Tag
    end

    it "raises if no model class is configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::RecordCreateSpec::TestHandlerWithoutConfiguration.new(request)

      expect_raises(Marten::Handlers::Errors::ImproperlyConfigured) { handler.model }
    end
  end

  describe "#post" do
    it "creates the new record and returns the expected redirect response if the schema is valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=newtag"
        )
      )
      handler = Marten::Handlers::RecordCreateSpec::TestHandler.new(request)

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
          body: "bad=bad"
        )
      )
      handler = Marten::Handlers::RecordCreateSpec::TestHandler.new(request)

      response = handler.post

      response.should be_a Marten::HTTP::Response
      response.status.should eq 200
      response.content.includes?("Schema is invalid").should be_true
    end
  end

  describe "#process_valid_schema" do
    it "creates the record and returns the expected redirect response" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=newtag"
        )
      )
      handler = Marten::Handlers::RecordCreateSpec::TestHandler.new(request)

      handler.schema.valid?
      response = handler.process_valid_schema

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")

      Marten::Handlers::RecordCreateSpec::Tag.filter(name: "newtag").exists?.should be_true
    end
  end

  describe "#record" do
    it "returns nil by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::RecordCreateSpec::TestHandler.new(request)

      handler.record.should be_nil
    end

    it "returns nil if the schema is invalid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "bad=bad"
        )
      )

      handler = Marten::Handlers::RecordCreateSpec::TestHandler.new(request)
      handler.dispatch

      handler.record.should be_nil
    end

    it "returns the created record if the schema is valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=newtag"
        )
      )
      handler = Marten::Handlers::RecordCreateSpec::TestHandler.new(request)

      handler.schema.valid?
      handler.dispatch

      Marten::Handlers::RecordCreateSpec::Tag.filter(name: "newtag").exists?.should be_true

      tag = Marten::Handlers::RecordCreateSpec::Tag.filter(name: "newtag").first
      handler.record.should eq tag
    end
  end
end

module Marten::Handlers::RecordCreateSpec
  class TestHandler < Marten::Handlers::RecordCreate
    model Tag
    schema TagCreateSchema
    success_route_name "dummy"
    template_name "specs/handlers/schema/test.html"
  end

  class TestHandlerWithoutConfiguration < Marten::Handlers::RecordCreate
  end
end
