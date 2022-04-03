require "./spec_helper"

describe Marten::Views::Defaults::BadRequest do
  describe "#dispatch" do
    it "returns a default text response if the 400.html template is not defined" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::Defaults::BadRequest.new(request)

      response = view.dispatch
      response.should be_a Marten::HTTP::Response::BadRequest
      response.content.should eq "Bad Request"
      response.content_type.should eq "text/plain"
    end

    context "with templates" do
      around_each do |t|
        original_template_loaders = Marten.templates.loaders

        Marten.templates.loaders = [] of Marten::Template::Loader::Base
        Marten.templates.loaders << Marten::Template::Loader::FileSystem.new("#{__DIR__}/bad_request_spec/templates")

        t.run

        Marten.templates.loaders = original_template_loaders
      end

      it "returns the rendered content of the 400.html template if it exists" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        view = Marten::Views::Defaults::BadRequest.new(request)

        response = view.dispatch
        response.should be_a Marten::HTTP::Response::BadRequest
        response.content.strip.should eq "BAD REQUEST"
        response.content_type.should eq "text/html"
      end

      it "returns the rendered content of a custom template if it exists" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        view = Marten::Views::Defaults::BadRequestSpec::TestView.new(request)

        response = view.dispatch
        response.should be_a Marten::HTTP::Response::BadRequest
        response.content.strip.should eq "CUSTOM BAD REQUEST"
        response.content_type.should eq "text/html"
      end

      it "raises TemplateNotFound if a custom template does not exist" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        view = Marten::Views::Defaults::BadRequestSpec::InvalidTestView.new(request)

        expect_raises(Marten::Template::Errors::TemplateNotFound) do
          view.dispatch
        end
      end
    end
  end
end

module Marten::Views::Defaults::BadRequestSpec
  class TestView < Marten::Views::Defaults::BadRequest
    template_name "custom_400.html"
  end

  class InvalidTestView < Marten::Views::Defaults::BadRequest
    template_name "invalid_400.html"
  end
end
