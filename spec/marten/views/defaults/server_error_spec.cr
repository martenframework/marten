require "./spec_helper"

describe Marten::Views::Defaults::ServerError do
  describe "#dispatch" do
    it "returns a default text response if the 500.html template is not defined" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::Defaults::ServerError.new(request)

      response = view.dispatch
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

        view = Marten::Views::Defaults::ServerError.new(request)

        response = view.dispatch
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

        view = Marten::Views::Defaults::ServerErrorSpec::TestView.new(request)

        response = view.dispatch
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

        view = Marten::Views::Defaults::ServerErrorSpec::InvalidTestView.new(request)

        expect_raises(Marten::Template::Errors::TemplateNotFound) do
          view.dispatch
        end
      end
    end
  end
end

module Marten::Views::Defaults::ServerErrorSpec
  class TestView < Marten::Views::Defaults::ServerError
    template_name "custom_500.html"
  end

  class InvalidTestView < Marten::Views::Defaults::ServerError
    template_name "invalid_500.html"
  end
end
