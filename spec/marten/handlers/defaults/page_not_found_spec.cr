require "./spec_helper"

describe Marten::Handlers::Defaults::PageNotFound do
  describe "#dispatch" do
    it "returns a default text response if the 404.html template is not defined" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::Defaults::PageNotFound.new(request)

      response = handler.dispatch
      response.should be_a Marten::HTTP::Response::NotFound
      response.content.should eq "The requested resource was not found."
      response.content_type.should eq "text/plain"
    end

    context "with templates" do
      around_each do |t|
        original_template_loaders = Marten.templates.loaders

        Marten.templates.loaders = [] of Marten::Template::Loader::Base
        Marten.templates.loaders << Marten::Template::Loader::FileSystem.new("#{__DIR__}/page_not_found_spec/templates")

        t.run

        Marten.templates.loaders = original_template_loaders
      end

      it "returns the rendered content of the 404.html template if it exists" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        handler = Marten::Handlers::Defaults::PageNotFound.new(request)

        response = handler.dispatch
        response.should be_a Marten::HTTP::Response::NotFound
        response.content.strip.should eq "PAGE NOT FOUND"
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

        handler = Marten::Handlers::Defaults::PageNotFoundSpec::TestHandler.new(request)

        response = handler.dispatch
        response.should be_a Marten::HTTP::Response::NotFound
        response.content.strip.should eq "CUSTOM PAGE NOT FOUND"
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

        handler = Marten::Handlers::Defaults::PageNotFoundSpec::InvalidTestHandler.new(request)

        expect_raises(Marten::Template::Errors::TemplateNotFound) do
          handler.dispatch
        end
      end
    end
  end
end

module Marten::Handlers::Defaults::PageNotFoundSpec
  class TestHandler < Marten::Handlers::Defaults::PageNotFound
    template_name "custom_404.html"
  end

  class InvalidTestHandler < Marten::Handlers::Defaults::PageNotFound
    template_name "invalid_404.html"
  end
end
