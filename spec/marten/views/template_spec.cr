require "./spec_helper"

describe Marten::Views::Template do
  describe "#context" do
    it "returns nil by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      Marten::Views::TemplateSpec::TestViewWithoutContext.new(request).context.should be_nil
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

      view = Marten::Views::TemplateSpec::TestView.new(request)
      response = view.get

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end
  end
end

module Marten::Views::TemplateSpec
  class TestView < Marten::Views::Template
    template "specs/views/template/test.html"

    def context
      {name: "John Doe"}
    end
  end

  class TestViewWithoutContext < Marten::Views::Template
  end
end
