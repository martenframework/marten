require "./spec_helper"

describe Marten::Template::Tag::CsrfInput do
  describe "::new" do
    it "raises if the csrf_input tag contains an argument" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed csrf_input tag: takes no argument"
      ) do
        Marten::Template::Tag::CsrfInput.new(parser, %(csrf_input "arg"))
      end
    end
  end

  describe "#render" do
    it "renders a html hidden input tag with csrftoken as name and handler's csrf_token as value" do
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
      context["handler"] = handler

      tag.render(context).includes?(%(<input type="hidden" name="csrftoken" value="#{handler.get_csrf_token}" />))
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
