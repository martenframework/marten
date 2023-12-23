require "./spec_helper"

describe Marten::Handlers::Schema do
  describe "::schema_context_name" do
    it "returns the expected value by default" do
      Marten::Handlers::SchemaSpec::TestHandler.schema_context_name.should eq "schema"
    end

    it "returns the specified value" do
      Marten::Handlers::SchemaSpec::TestWithCustomSchemaContextName.schema_context_name.should eq "my_schema"
    end
  end

  describe "::schema_context_name(name)" do
    it "allows to specify the schema context name" do
      Marten::Handlers::SchemaSpec::TestWithCustomSchemaContextName.schema_context_name("my_schema")
      Marten::Handlers::SchemaSpec::TestWithCustomSchemaContextName.schema_context_name.should eq "my_schema"
    end
  end

  describe "::success_route_name" do
    it "returns the configured success URL" do
      Marten::Handlers::SchemaSpec::TestHandler.success_route_name.should eq "dummy"
    end

    it "returns nil by default" do
      Marten::Handlers::SchemaSpec::TestHandlerWithoutConfiguration.success_route_name.should be_nil
    end
  end

  describe "::success_url" do
    it "returns the configured success URL" do
      Marten::Handlers::SchemaSpec::TestHandlerWithSuccessUrl.success_url.should eq "https://example.com"
    end

    it "returns nil by default" do
      Marten::Handlers::SchemaSpec::TestHandlerWithoutConfiguration.success_url.should be_nil
    end
  end

  describe "#render_to_response" do
    it "includes the schema instance without data in the global context if the request does not provide data" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.render_to_response(context: nil)

      handler.context["schema"].raw.should be_a Marten::Handlers::SchemaSpec::TestSchema
      schema = handler.context["schema"].raw.as(Marten::Schema)
      schema["foo"].value.should be_nil
      schema["bar"].value.should be_nil
    end

    it "includes the schema instance with data in the global context if the request provides data" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.render_to_response(context: nil)

      handler.context["schema"].raw.should be_a Marten::Handlers::SchemaSpec::TestSchema
      schema = handler.context["schema"].raw.as(Marten::Schema)
      schema["foo"].value.should eq "123"
      schema["bar"].value.should eq "456"
    end
  end

  describe "#post" do
    it "returns the expected redirect response if the schema is valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      response = handler.post

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")
    end

    it "re-renders the template if the schema is not valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      response = handler.post

      response.should be_a Marten::HTTP::Response
      response.status.should eq 200
      response.content.includes?("Schema is invalid").should be_true
    end
  end

  describe "#process_invalid_schema" do
    it "re-renders the template" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.schema.valid?
      response = handler.process_invalid_schema

      response.should be_a Marten::HTTP::Response
      response.status.should eq 200
      response.content.includes?("Schema is invalid").should be_true
    end
  end

  describe "#process_valid_schema" do
    it "returns the expected redirect response" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.schema.valid?
      response = handler.process_valid_schema

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")
    end
  end

  describe "#put" do
    it "returns the expected redirect response if the schema is valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      response = handler.put

      response.should be_a Marten::HTTP::Response::Found
      response.as(Marten::HTTP::Response::Found).headers["Location"].should eq Marten.routes.reverse("dummy")
    end

    it "re-renders the template if the schema is not valid" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      response = handler.put

      response.should be_a Marten::HTTP::Response
      response.status.should eq 200
      response.content.includes?("Schema is invalid").should be_true
    end
  end

  describe "#schema" do
    it "returns the schema initialized with the request data" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.schema.should be_a Marten::Handlers::SchemaSpec::TestSchema
      handler.schema["foo"].value.should eq "123"
      handler.schema["bar"].value.should eq "456"
    end
  end

  describe "#schema_class" do
    it "returns the configured schema class" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.schema_class.should eq Marten::Handlers::SchemaSpec::TestSchema
    end

    it "raises if no schema class is configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=123&bar=456"
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandlerWithoutConfiguration.new(request)

      expect_raises(Marten::Handlers::Errors::ImproperlyConfigured) { handler.schema_class }
    end
  end

  describe "#post" do
    it "executes success callback" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandlerWithSuccessCallbacks.new(request)

      handler.foo.should eq nil
      handler.bar.should eq nil
      handler.baz.should eq nil
      handler.foobar.should eq nil

      handler.post

      handler.schema.valid?.should eq true
      handler.foo.should eq "set_foo"
      handler.bar.should eq "set_bar"
      handler.baz.should eq "set_baz"
      handler.foobar.should eq nil
    end

    it "executes failed callback" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "POST",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandlerWithFailedCallbacks.new(request)

      handler.foo.should eq nil
      handler.bar.should eq nil
      handler.baz.should eq nil
      handler.foobar.should eq nil

      handler.post

      handler.schema.valid?.should eq false
      handler.foo.should eq "set_foo"
      handler.bar.should eq "set_bar"
      handler.baz.should eq nil
      handler.foobar.should eq "set_foobar"
    end

    it "returns any early response returned by the before_schema_validation callbacks" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::SchemaSpec::TestHandlerWithBeforeValidateResponse.new(request)

      response = handler.post
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "before_schema_validation response"
    end

    it "returns any early response returned by the after_schema_validation callbacks" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::SchemaSpec::TestHandlerWithAfterValidateResponse.new(request)

      response = handler.post
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "after_schema_validation response"
    end

    it "returns any early response returned by the after_successful_schema_validation callbacks" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::SchemaSpec::TestHandlerWithAfterSuccessfulValidateResponse.new(request)

      response = handler.post
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "after_successful_schema_validation response"
    end

    it "returns any early response returned by the after_failed_schema_validation callbacks" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::SchemaSpec::TestHandlerWithAfterFailedValidateResponse.new(request)

      response = handler.post
      response.status.should eq 200
      response.content_type.should eq "text/plain"
      response.content.should eq "after_failed_schema_validation response"
    end
  end

  describe "#success_url" do
    it "returns the raw success URL if configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandlerWithSuccessUrl.new(request)

      handler.success_url.should eq "https://example.com"
    end

    it "returns the resolved success route if configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandler.new(request)

      handler.success_url.should eq Marten.routes.reverse("dummy")
    end

    it "raises if no success URL is configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::SchemaSpec::TestHandlerWithoutConfiguration.new(request)

      expect_raises(Marten::Handlers::Errors::ImproperlyConfigured) { handler.success_url }
    end
  end
end

module Marten::Handlers::SchemaSpec
  class TestSchema < Marten::Schema
    field :foo, :string
    field :bar, :string
  end

  class EmptySchema < Marten::Schema
  end

  class TestHandler < Marten::Handlers::Schema
    schema TestSchema
    success_route_name "dummy"
    template_name "specs/handlers/schema/test.html"
  end

  class TestHandlerWithSuccessUrl < Marten::Handlers::Schema
    schema TestSchema
    success_url "https://example.com"
  end

  class TestHandlerWithSuccessCallbacks < Marten::Handlers::Schema
    property foo : String? = nil
    property bar : String? = nil
    property baz : String? = nil
    property foobar : String? = nil
    success_url "https://example.com"
    template_name "specs/handlers/schema/test.html"
    schema EmptySchema

    before_schema_validation :set_foo
    after_schema_validation :set_bar
    after_successful_schema_validation :set_baz
    after_failed_schema_validation :set_foobar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end

    private def set_baz
      self.baz = "set_baz"
    end

    private def set_foobar
      self.foobar = "set_foobar"
    end
  end

  class TestHandlerWithFailedCallbacks < Marten::Handlers::Schema
    property foo : String? = nil
    property bar : String? = nil
    property baz : String? = nil
    property foobar : String? = nil
    success_url "https://example.com"
    template_name "specs/handlers/schema/test.html"
    schema TestSchema

    before_schema_validation :set_foo
    after_schema_validation :set_bar
    after_successful_schema_validation :set_baz
    after_failed_schema_validation :set_foobar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end

    private def set_baz
      self.baz = "set_baz"
    end

    private def set_foobar
      self.foobar = "set_foobar"
    end
  end

  class TestHandlerWithBeforeValidateResponse < Marten::Handlers::Schema
    before_schema_validation :return_before_schema_validation_response
    success_url "https://example.com"
    template_name "specs/handlers/schema/test.html"
    schema TestSchema

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def return_before_schema_validation_response
      Marten::HTTP::Response.new("before_schema_validation response", content_type: "text/plain", status: 200)
    end
  end

  class TestHandlerWithAfterValidateResponse < Marten::Handlers::Schema
    after_schema_validation :return_after_schema_validation_response
    success_url "https://example.com"
    template_name "specs/handlers/schema/test.html"
    schema TestSchema

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def return_after_schema_validation_response
      Marten::HTTP::Response.new("after_schema_validation response", content_type: "text/plain", status: 200)
    end
  end

  class TestHandlerWithAfterSuccessfulValidateResponse < Marten::Handlers::Schema
    after_successful_schema_validation :return_after_successful_schema_validation_response
    success_url "https://example.com"
    template_name "specs/handlers/schema/test.html"
    schema EmptySchema

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def return_after_successful_schema_validation_response
      Marten::HTTP::Response.new("after_successful_schema_validation response", content_type: "text/plain", status: 200)
    end
  end

  class TestHandlerWithAfterFailedValidateResponse < Marten::Handlers::Schema
    after_failed_schema_validation :return_after_failed_schema_validation_response
    success_url "https://example.com"
    template_name "specs/handlers/schema/test.html"
    schema TestSchema

    def get
      Marten::HTTP::Response.new("Regular response", content_type: "text/plain", status: 200)
    end

    private def return_after_failed_schema_validation_response
      Marten::HTTP::Response.new("after_failed_schema_validation response", content_type: "text/plain", status: 200)
    end
  end

  class TestHandlerWithoutConfiguration < Marten::Handlers::Schema
  end

  class TestWithCustomSchemaContextName < Marten::Handlers::Schema
    schema TestSchema
    schema_context_name "my_schema"
  end
end
