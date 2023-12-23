require "./spec_helper"

describe Marten::Handlers::Template do
  describe "#get" do
    it "returns a HTTP response containing the template rendered using the specified context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::TemplateSpec::TestHandler.new(request)
      response = handler.get

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end
  end
end

module Marten::Handlers::TemplateSpec
  class TestHandler < Marten::Handlers::Template
    template_name "specs/handlers/template/test.html"

    before_render :add_name_to_context

    private def add_name_to_context
      context[:name] = "John Doe"
    end
  end

  class TestHandlerWithoutContext < Marten::Handlers::Template
  end
end
