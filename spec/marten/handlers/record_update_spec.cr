require "./spec_helper"
require "./record_update_spec/**"

describe Marten::Handlers::RecordUpdate do
  with_installed_apps Marten::Handlers::RecordUpdateSpec::App

  describe "::record_context_name" do
    it "returns the configured context name for the record" do
      Marten::Handlers::RecordUpdateSpec::TestHandler.record_context_name.should eq "tag"
    end

    it "returns `record` by default" do
      Marten::Handlers::RecordUpdateSpec::TestHandlerWithoutConfiguration.record_context_name.should eq "record"
    end
  end

  describe "#render_to_response" do
    it "includes the record to update and the schema in the global context" do
      tag = Marten::Handlers::RecordUpdateSpec::Tag.create(name: "oldtag")

      params = Marten::Routing::MatchParameters{"pk" => tag.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=updatedtag"
        )
      )
      handler = Marten::Handlers::RecordUpdateSpec::TestHandler.new(request, params)

      handler.render_to_response(context: nil)

      handler.context["schema"].raw.should be_a Marten::Handlers::RecordUpdateSpec::TagSchema
      handler.context["tag"].should eq tag
    end
  end

  describe "#post" do
    it "updates an existing record and returns the expected redirect response if the schema is valid" do
      tag = Marten::Handlers::RecordUpdateSpec::Tag.create(name: "oldtag")

      params = Marten::Routing::MatchParameters{"pk" => tag.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=updatedtag"
        )
      )
      handler = Marten::Handlers::RecordUpdateSpec::TestHandler.new(request, params)

      response = handler.post

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")
      tag.reload.name.should eq "updatedtag"
    end

    it "is able to do partial updatesà" do
      tag = Marten::Handlers::RecordUpdateSpec::Tag.create(name: "oldtag", description: "This is a tag")

      params = Marten::Routing::MatchParameters{"pk" => tag.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=updatedtag"
        )
      )
      handler = Marten::Handlers::RecordUpdateSpec::TestHandler.new(request, params)

      response = handler.post

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")

      tag.reload
      tag.name.should eq "updatedtag"
      tag.description.should eq "This is a tag"
    end

    it "re-renders the template if the schema is not valid and does not update the record" do
      tag = Marten::Handlers::RecordUpdateSpec::Tag.create(name: "oldtag")

      params = Marten::Routing::MatchParameters{"pk" => tag.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=0"
        )
      )
      handler = Marten::Handlers::RecordUpdateSpec::TestHandler.new(request, params)

      response = handler.post

      response.should be_a Marten::HTTP::Response
      response.status.should eq 200
      response.content.includes?("Schema is invalid").should be_true
      tag.reload.name.should eq "oldtag"
    end
  end

  describe "#process_valid_schema" do
    it "updates the record and returns the expected redirect response" do
      tag = Marten::Handlers::RecordUpdateSpec::Tag.create(name: "oldtag")

      params = Marten::Routing::MatchParameters{"pk" => tag.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=updatedtag"
        )
      )
      handler = Marten::Handlers::RecordUpdateSpec::TestHandler.new(request, params)

      handler.schema.valid?
      response = handler.process_valid_schema

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")

      tag.reload.name.should eq "updatedtag"
    end
  end
end

module Marten::Handlers::RecordUpdateSpec
  class TestHandler < Marten::Handlers::RecordUpdate
    model Tag
    schema TagSchema
    success_route_name "dummy"
    template_name "specs/handlers/schema/test.html"
    record_context_name "tag"
  end

  class TestHandlerWithoutConfiguration < Marten::Handlers::RecordUpdate
  end
end
