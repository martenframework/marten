require "./spec_helper"

describe Marten::Template::Tag::CsrfInput do
  describe "::new" do
    it "can initialize a CSRF token tag without assignment" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::CsrfInput.new(parser, "csrf_input")
      tag.should be_a Marten::Template::Tag::CsrfInput

      handler = Marten::Template::Tag::CsrfInputSpec::TestHandler.new(
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

      tag = Marten::Template::Tag::CsrfInput.new(parser, "csrf_input as my_var")
      tag.should be_a Marten::Template::Tag::CsrfInput

      handler = Marten::Template::Tag::CsrfInputSpec::TestHandler.new(
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
      ["csrf_input as", "csrf_input as my_var other_var"].each do |raw_tag|
        expect_raises(
          Marten::Template::Errors::InvalidSyntax,
          "Malformed csrf_input tag: either no arguments or two arguments expected"
        ) do
          Marten::Template::Tag::CsrfInput.new(Marten::Template::Parser.new(""), raw_tag)
        end
      end

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed csrf_input tag: 'as' keyword expected"
      ) do
        Marten::Template::Tag::CsrfInput.new(Marten::Template::Parser.new(""), "csrf_input to my_var")
      end
    end
  end

  describe "#render" do
    it "returns the CSRF input if the handler is in the context" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::CsrfInput.new(parser, "csrf_input")
      tag.should be_a Marten::Template::Tag::CsrfInput

      handler = Marten::Template::Tag::CsrfInputSpec::TestHandler.new(
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

      tag.render(context).matches?(/<input type="hidden" name="csrftoken" value=".+" \/>/).should be_true
    end

    it "returns an empty string if no handler is associated with the context" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::CsrfInput.new(parser, "csrf_input")
      tag.should be_a Marten::Template::Tag::CsrfInput

      handler = Marten::Template::Tag::CsrfInputSpec::TestHandler.new(
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

      tag.render(context).should be_empty
    end

    it "assigns the CSRF token to the specified variable if applicable" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::CsrfInput.new(parser, "csrf_input as my_var")
      tag.should be_a Marten::Template::Tag::CsrfInput

      handler = Marten::Template::Tag::CsrfInputSpec::TestHandler.new(
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
      context["my_var"].raw.should be_a Marten::Template::SafeString
      context["my_var"].to_s.matches?(/<input type="hidden" name="csrftoken" value=".+" \/>/).should be_true
    end
  end
end

module Marten::Template::Tag::CsrfInputSpec
  class TestHandler < Marten::Handler
    def get
      respond "OK"
    end
  end
end
