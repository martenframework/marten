require "./spec_helper"
require "./record_create_spec/**"

describe Marten::Views::RecordCreate do
  with_installed_apps Marten::Views::RecordCreateSpec::App

  describe "::model" do
    it "returns nil by default" do
      Marten::Views::RecordCreateSpec::TestViewWithoutConfiguration.model.should be_nil
    end

    it "returns the configured model class" do
      Marten::Views::RecordCreateSpec::TestView.model.should eq Marten::Views::RecordCreateSpec::Tag
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
      view = Marten::Views::RecordCreateSpec::TestView.new(request)

      view.model.should eq Marten::Views::RecordCreateSpec::Tag
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
      view = Marten::Views::RecordCreateSpec::TestViewWithoutConfiguration.new(request)

      expect_raises(Marten::Views::Errors::ImproperlyConfigured) { view.model }
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
      view = Marten::Views::RecordCreateSpec::TestView.new(request)

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
          body: "bad=bad"
        )
      )
      view = Marten::Views::RecordCreateSpec::TestView.new(request)

      response = view.post

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
      view = Marten::Views::RecordCreateSpec::TestView.new(request)

      view.schema.valid?
      response = view.process_valid_schema

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")

      Marten::Views::RecordCreateSpec::Tag.filter(name: "newtag").exists?.should be_true
    end
  end
end

module Marten::Views::RecordCreateSpec
  class TestView < Marten::Views::RecordCreate
    model Tag
    schema TagCreateSchema
    success_route_name "dummy"
    template_name "specs/views/schema/test.html"
  end

  class TestViewWithoutConfiguration < Marten::Views::RecordCreate
  end
end
