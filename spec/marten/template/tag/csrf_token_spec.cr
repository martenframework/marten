require "./spec_helper"

describe Marten::Template::Tag::CsrfToken do
  describe "#render" do
    it "returns the CSRF token if the handler is in the context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Template::Tag::CsrfTokenSpec::TestHandler.new(request)
      handler.process_dispatch

      parser = Marten::Template::Parser.new("")

      context = Marten::Template::Context.new
      context["handler"] = handler

      tag = Marten::Template::Tag::CsrfToken.new(parser, "csrf_token")
      rendered = tag.render(context)

      rendered.should_not be_empty
    end

    it "returns an empty string if no handler is in the context" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Template::Tag::CsrfTokenSpec::TestHandler.new(request)
      handler.process_dispatch

      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::CsrfToken.new(parser, "csrf_token")
      tag.render(Marten::Template::Context.new).should be_empty
    end

    it "returns if the handler context key is not an actual handler" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Template::Tag::CsrfTokenSpec::TestHandler.new(request)
      handler.process_dispatch

      parser = Marten::Template::Parser.new("")

      context = Marten::Template::Context.new
      context["handler"] = 42

      tag = Marten::Template::Tag::CsrfToken.new(parser, "csrf_token")
      tag.render(context).should be_empty
    end
  end
end

module Marten::Template::Tag::CsrfTokenSpec
  class TestHandler < Marten::Handler
    def get
      respond "OK"
    end
  end
end
