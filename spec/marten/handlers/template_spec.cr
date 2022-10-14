require "./spec_helper"

describe Marten::Handlers::Template do
  describe "#context" do
    it "returns nil by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      Marten::Handlers::TemplateSpec::TestHandlerWithoutContext.new(request).context.should be_nil
    end
  end

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

    def context
      {name: "John Doe"}
    end
  end

  class TestHandlerWithoutContext < Marten::Handlers::Template
  end
end
