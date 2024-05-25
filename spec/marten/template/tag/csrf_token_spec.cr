require "./spec_helper"

describe Marten::Template::Tag::CsrfToken do
  describe "::new" do
    it "can initialize a CSRF token tag without assignment" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::CsrfToken.new(parser, "csrf_token")
      tag.should be_a Marten::Template::Tag::CsrfToken

      handler = Marten::Template::Tag::CsrfTokenSpec::TestHandler.new(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/test/xyz",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )
      )
      handler.process_dispatch

      context = Marten::Template::Context.new
      context.handler = handler

      tag.render(context).should_not be_empty
    end

    it "can initialize a CSRF token tag with an assignment" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::CsrfToken.new(parser, "csrf_token as my_var")
      tag.should be_a Marten::Template::Tag::CsrfToken

      handler = Marten::Template::Tag::CsrfTokenSpec::TestHandler.new(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/test/xyz",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )
      )
      handler.process_dispatch

      context = Marten::Template::Context.new
      context.handler = handler

      tag.render(context).should be_empty
      context["my_var"].should_not be_empty
    end

    it "raises if the CSRF token tag's syntax is invalid" do
      ["csrf_token as", "csrf_token as my_var other_var"].each do |raw_tag|
        expect_raises(
          Marten::Template::Errors::InvalidSyntax,
          "Malformed csrf_token tag: either no arguments or two arguments expected"
        ) do
          Marten::Template::Tag::CsrfToken.new(Marten::Template::Parser.new(""), raw_tag)
        end
      end

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed csrf_token tag: 'as' keyword expected"
      ) do
        Marten::Template::Tag::CsrfToken.new(Marten::Template::Parser.new(""), "csrf_token to my_var")
      end
    end
  end

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
      context.handler = handler

      tag = Marten::Template::Tag::CsrfToken.new(parser, "csrf_token")
      rendered = tag.render(context)

      rendered.should_not be_empty
    end

    it "returns an empty string if no handler is associated with the context" do
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

    it "assigns the CSRF token to the specified variable if applicable" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::CsrfToken.new(parser, "csrf_token as my_var")
      tag.should be_a Marten::Template::Tag::CsrfToken

      handler = Marten::Template::Tag::CsrfTokenSpec::TestHandler.new(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/test/xyz",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )
      )
      handler.process_dispatch

      context = Marten::Template::Context.new
      context.handler = handler

      tag.render(context).should be_empty
      context["my_var"].should_not be_empty
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
