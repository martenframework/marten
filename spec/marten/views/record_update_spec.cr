require "./spec_helper"
require "./record_update_spec/**"

describe Marten::Views::RecordUpdate do
  with_installed_apps Marten::Views::RecordUpdateSpec::App

  describe "#post" do
    it "updates an existing record and returns the expected redirect response if the schema is valid" do
      tag = Marten::Views::RecordUpdateSpec::Tag.create(name: "oldtag")

      params = Hash(String, Marten::Routing::Parameter::Types){"pk" => tag.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=updatedtag"
        )
      )
      view = Marten::Views::RecordUpdateSpec::TestView.new(request, params)

      response = view.post

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")
      tag.reload.name.should eq "updatedtag"
    end

    it "is able to do partial updatesà" do
      tag = Marten::Views::RecordUpdateSpec::Tag.create(name: "oldtag", description: "This is a tag")

      params = Hash(String, Marten::Routing::Parameter::Types){"pk" => tag.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=updatedtag"
        )
      )
      view = Marten::Views::RecordUpdateSpec::TestView.new(request, params)

      response = view.post

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")

      tag.reload
      tag.name.should eq "updatedtag"
      tag.description.should eq "This is a tag"
    end

    it "re-renders the template if the schema is not valid and does not update the record" do
      tag = Marten::Views::RecordUpdateSpec::Tag.create(name: "oldtag")

      params = Hash(String, Marten::Routing::Parameter::Types){"pk" => tag.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=0"
        )
      )
      view = Marten::Views::RecordUpdateSpec::TestView.new(request, params)

      response = view.post

      response.should be_a Marten::HTTP::Response
      response.status.should eq 200
      response.content.includes?("Schema is invalid").should be_true
      tag.reload.name.should eq "oldtag"
    end
  end

  describe "#process_valid_schema" do
    it "updates the record and returns the expected redirect response" do
      tag = Marten::Views::RecordUpdateSpec::Tag.create(name: "oldtag")

      params = Hash(String, Marten::Routing::Parameter::Types){"pk" => tag.id!}
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "name=updatedtag"
        )
      )
      view = Marten::Views::RecordUpdateSpec::TestView.new(request, params)

      view.schema.valid?
      response = view.process_valid_schema

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")

      tag.reload.name.should eq "updatedtag"
    end
  end
end

module Marten::Views::RecordUpdateSpec
  class TestView < Marten::Views::RecordUpdate
    model Tag
    schema TagSchema
    success_route_name "dummy"
    template_name "specs/views/schema/test.html"
  end
end
