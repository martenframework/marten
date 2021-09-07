require "./spec_helper"

describe Marten::Views::Rendering do
  describe "::template_name(template)" do
    it "allows to configure the template associated with the considered view" do
      Marten::Views::RenderingSpec::TestView.template_name.should eq "specs/views/concerns/rendering/test.html"
    end
  end

  describe "::template_name" do
    it "returns the configured template name" do
      Marten::Views::RenderingSpec::TestView.template_name.should eq "specs/views/concerns/rendering/test.html"
    end

    it "returns nil by default" do
      Marten::Views::RenderingSpec::TestViewWithoutTemplate.template_name.should be_nil
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

      response = Marten::Views::RenderingSpec::TestView.new(request).render_to_response({"name" => "John Doe"})

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
        Marten::Template::Context{"name" => "John Doe"}
      )

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end
  end

  describe "#template_name" do
    it "returns the configured template name by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::RenderingSpec::TestView.new(request)

      view.template_name.should eq "specs/views/concerns/rendering/test.html"
    end

    it "raises an error if the template name is not configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::RenderingSpec::TestViewWithoutTemplate.new(request)

      expect_raises(
        Marten::Views::Errors::ImproperlyConfigured,
        "'Marten::Views::RenderingSpec::TestViewWithoutTemplate' must define a template name via the " \
        "'::template_name' class method method or by overriding the '#template_name' method"
      ) do
        view.template_name
      end
    end
  end
end

module Marten::Views::RenderingSpec
  class TestView < Marten::View
    include Marten::Views::Rendering

    template_name "specs/views/concerns/rendering/test.html"
  end

  class TestViewWithoutTemplate < Marten::View
    include Marten::Views::Rendering
  end
end
