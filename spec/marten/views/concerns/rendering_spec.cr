require "./spec_helper"

describe Marten::Views::Rendering do
  describe "::template(template)" do
    it "allows to configure the template associated with the considered view" do
      Marten::Views::RenderingSpec::TestView.template.should eq "specs/views/concerns/rendering/test.html"
    end
  end

  describe "::template" do
    it "returns the configured template name" do
      Marten::Views::RenderingSpec::TestView.template.should eq "specs/views/concerns/rendering/test.html"
    end

    it "returns nil by default" do
      Marten::Views::RenderingSpec::TestViewWithoutTemplate.template.should be_nil
    end
  end

  describe "#context" do
    it "returns nil by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      Marten::Views::RenderingSpec::TestViewWithoutTemplate.new(request).context.should be_nil
    end
  end

  describe "#render_to_response" do
    it "returns an HTTP response containing the template rendered using the configured context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      response = Marten::Views::RenderingSpec::TestView.new(request).render_to_response({name: "John Doe"})

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "is able to render the template using a named tuple context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      response = Marten::Views::RenderingSpec::TestView.new(request).render_to_response({name: "John Doe"})

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "is able to render the template using a hash context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      response = Marten::Views::RenderingSpec::TestView.new(request).render_to_response({ "name" => "John Doe"})

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "is able to render the template using a context object" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      response = Marten::Views::RenderingSpec::TestView.new(request).render_to_response(
        Marten::Template::Context{ "name" => "John Doe"}
      )

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end
  end
end

module Marten::Views::RenderingSpec
  class TestView < Marten::View
    include Marten::Views::Rendering

    template "specs/views/concerns/rendering/test.html"
  end

  class TestViewWithoutTemplate < Marten::View
    include Marten::Views::Rendering
  end
end
