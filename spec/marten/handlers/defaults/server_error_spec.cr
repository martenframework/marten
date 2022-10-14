require "./spec_helper"

describe Marten::Handlers::Defaults::ServerError do
  describe "#dispatch" do
    it "returns a default text response if the 500.html template is not defined" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::Defaults::ServerError.new(request)

      response = handler.dispatch
      response.should be_a Marten::HTTP::Response::InternalServerError
      response.content.should eq "Internal Server Error"
      response.content_type.should eq "text/plain"
    end

    context "with templates" do
      around_each do |t|
        original_template_loaders = Marten.templates.loaders

        Marten.templates.loaders = [] of Marten::Template::Loader::Base
        Marten.templates.loaders << Marten::Template::Loader::FileSystem.new("#{__DIR__}/server_error_spec/templates")

        t.run

        Marten.templates.loaders = original_template_loaders
      end

      it "returns the rendered content of the 500.html template if it exists" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        handler = Marten::Handlers::Defaults::ServerError.new(request)

        response = handler.dispatch
        response.should be_a Marten::HTTP::Response::InternalServerError
        response.content.strip.should eq "SERVER ERROR"
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

        handler = Marten::Handlers::Defaults::ServerErrorSpec::TestHandler.new(request)

        response = handler.dispatch
        response.should be_a Marten::HTTP::Response::InternalServerError
        response.content.strip.should eq "CUSTOM SERVER ERROR"
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

        handler = Marten::Handlers::Defaults::ServerErrorSpec::InvalidTestHandler.new(request)

        expect_raises(Marten::Template::Errors::TemplateNotFound) do
          handler.dispatch
        end
      end
    end
  end
end

module Marten::Handlers::Defaults::ServerErrorSpec
  class TestHandler < Marten::Handlers::Defaults::ServerError
    template_name "custom_500.html"
  end

  class InvalidTestHandler < Marten::Handlers::Defaults::ServerError
    template_name "invalid_500.html"
  end
end
