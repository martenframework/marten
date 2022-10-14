require "./spec_helper"

describe Marten::Handlers::Defaults::PermissionDenied do
  describe "#dispatch" do
    it "returns a default text response if the 403.html template is not defined" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::Defaults::PermissionDenied.new(request)

      response = handler.dispatch
      response.should be_a Marten::HTTP::Response::Forbidden
      response.content.should eq "403 Forbidden"
      response.content_type.should eq "text/plain"
    end

    context "with templates" do
      around_each do |t|
        original_template_loaders = Marten.templates.loaders

        Marten.templates.loaders = [] of Marten::Template::Loader::Base
        Marten.templates.loaders << Marten::Template::Loader::FileSystem.new(
          "#{__DIR__}/permission_denied_spec/templates"
        )

        t.run

        Marten.templates.loaders = original_template_loaders
      end

      it "returns the rendered content of the 403.html template if it exists" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        handler = Marten::Handlers::Defaults::PermissionDenied.new(request)

        response = handler.dispatch
        response.should be_a Marten::HTTP::Response::Forbidden
        response.content.strip.should eq "PERMISSION DENIED"
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

        handler = Marten::Handlers::Defaults::PermissionDeniedSpec::TestHandler.new(request)

        response = handler.dispatch
        response.should be_a Marten::HTTP::Response::Forbidden
        response.content.strip.should eq "CUSTOM PERMISSION DENIED"
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

        handler = Marten::Handlers::Defaults::PermissionDeniedSpec::InvalidTestHandler.new(request)

        expect_raises(Marten::Template::Errors::TemplateNotFound) do
          handler.dispatch
        end
      end
    end
  end
end

module Marten::Handlers::Defaults::PermissionDeniedSpec
  class TestHandler < Marten::Handlers::Defaults::PermissionDenied
    template_name "custom_403.html"
  end

  class InvalidTestHandler < Marten::Handlers::Defaults::PermissionDenied
    template_name "invalid_403.html"
  end
end
