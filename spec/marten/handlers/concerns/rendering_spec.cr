require "./spec_helper"

describe Marten::Handlers::Rendering do
  describe "::template_name(template)" do
    it "allows to configure the template associated with the considered handler" do
      Marten::Handlers::RenderingSpec::TestHandler.template_name.should eq "specs/handlers/concerns/rendering/test.html"
    end
  end

  describe "::template_name" do
    it "returns the configured template name" do
      Marten::Handlers::RenderingSpec::TestHandler.template_name.should eq "specs/handlers/concerns/rendering/test.html"
    end

    it "returns nil by default" do
      Marten::Handlers::RenderingSpec::TestHandlerWithoutTemplate.template_name.should be_nil
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

      response = Marten::Handlers::RenderingSpec::TestHandler.new(request).render_to_response({name: "John Doe"})

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

      response = Marten::Handlers::RenderingSpec::TestHandler.new(request).render_to_response({name: "John Doe"})

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

      response = Marten::Handlers::RenderingSpec::TestHandler.new(request).render_to_response({"name" => "John Doe"})

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

      response = Marten::Handlers::RenderingSpec::TestHandler.new(request).render_to_response(
        Marten::Template::Context{"name" => "John Doe"}
      )

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "is able to render the template using the global context" do
      handler = Marten::Handlers::RenderingSpec::TestHandler.new(
        Marten::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler.context["name"] = "John Doe"

      response = handler.render_to_response(nil)

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq "Hello World, John Doe!"
    end

    it "includes the handler in the context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::RenderingSpec::TestHandlerWithHandlerTemplate.new(request)
      response = handler.render_to_response(nil)

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq HTML.escape(handler.to_s)
    end

    it "runs before_render callbacks as expected" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::RenderingSpec::TestHandlerWithCallback.new(request)

      handler.xyz.should be_nil

      response = handler.render_to_response(nil)

      handler.xyz.should eq "set_xyz"

      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.strip.should eq HTML.escape(handler.to_s)
    end

    it "returns the expected response if the before_render callback returns a custom responses" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::RenderingSpec::TestHandlerWithBeforeRenderResponse.new(request)

      response = handler.render_to_response(nil)

      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "before_render response"
    end

    it "returns the expected response if the before_render callback returns a value that is not an HTTP response" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::RenderingSpec::TestHandlerWithContextBeforeRenderResponse.new(request)

      response = handler.render_to_response(nil)

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
      handler = Marten::Handlers::RenderingSpec::TestHandler.new(request)

      handler.template_name.should eq "specs/handlers/concerns/rendering/test.html"
    end

    it "raises an error if the template name is not configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RenderingSpec::TestHandlerWithoutTemplate.new(request)

      expect_raises(
        Marten::Handlers::Errors::ImproperlyConfigured,
        "'Marten::Handlers::RenderingSpec::TestHandlerWithoutTemplate' must define a template name via the " \
        "'::template_name' class method method or by overriding the '#template_name' method"
      ) do
        handler.template_name
      end
    end
  end
end

module Marten::Handlers::RenderingSpec
  class TestHandler < Marten::Handler
    include Marten::Handlers::Rendering

    template_name "specs/handlers/concerns/rendering/test.html"
  end

  class TestHandlerWithHandlerTemplate < Marten::Handler
    include Marten::Handlers::Rendering

    template_name "specs/handlers/concerns/rendering/handler.html"
  end

  class TestHandlerWithCallback < Marten::Handler
    include Marten::Handlers::Rendering

    property xyz : String? = nil

    template_name "specs/handlers/concerns/rendering/handler.html"

    before_render :set_xyz

    private def set_xyz
      self.xyz = "set_xyz"
    end
  end

  class TestHandlerWithBeforeRenderResponse < Marten::Handler
    include Marten::Handlers::Rendering

    template_name "specs/handlers/concerns/rendering/handler.html"

    before_render :return_before_render_response

    private def return_before_render_response
      Marten::HTTP::Response.new("before_render response", content_type: "text/plain", status: 200)
    end
  end

  class TestHandlerWithContextBeforeRenderResponse < Marten::Handler
    include Marten::Handlers::Rendering

    template_name "specs/handlers/concerns/rendering/test.html"

    before_render :add_context_values

    private def add_context_values
      context["name"] = "John Doe"
      "bar"
    end
  end

  class TestHandlerWithoutTemplate < Marten::Handler
    include Marten::Handlers::Rendering
  end
end
