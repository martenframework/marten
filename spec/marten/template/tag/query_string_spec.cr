require "./spec_helper"

describe Marten::Template::Tag::QueryString do
  describe "#render" do
    it "returns a question mark when the request query string is empty" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring")

      tag.render(Marten::Template::Tag::QueryStringSpec.context).should eq "?"
    end

    it "returns the current request query string" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring")

      tag.render(Marten::Template::Tag::QueryStringSpec.context("color=green")).should eq "?color=green"
      tag.render(Marten::Template::Tag::QueryStringSpec.context("x=y&a=b")).should eq "?x=y&amp;a=b"
    end

    it "preserves repeated query parameters" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring")

      tag.render(Marten::Template::Tag::QueryStringSpec.context("x=y&x=z&a=b&a=c")).should eq(
        "?x=y&amp;x=z&amp;a=b&amp;a=c"
      )
    end

    it "adds and replaces parameters" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::QueryString.new(parser, %{querystring size: "M"})
      tag.render(Marten::Template::Tag::QueryStringSpec.context("color=green")).should eq "?color=green&amp;size=M"

      tag = Marten::Template::Tag::QueryString.new(parser, %{querystring color: "red", size: "S"})
      tag.render(Marten::Template::Tag::QueryStringSpec.context("color=green")).should eq "?color=red&amp;size=S"
    end

    it "keeps an existing parameter in place when replacing its value" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring a: 1")

      tag.render(Marten::Template::Tag::QueryStringSpec.context("x=y&a=b")).should eq "?x=y&amp;a=1"
    end

    it "removes a parameter when the value is nil" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring color: nil")

      tag.render(Marten::Template::Tag::QueryStringSpec.context("color=green&size=M")).should eq "?size=M"
    end

    it "returns a question mark when every parameter is removed" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring a: nil")

      tag.render(Marten::Template::Tag::QueryStringSpec.context("a=b")).should eq "?"
      tag.render(Marten::Template::Tag::QueryStringSpec.context).should eq "?"
    end

    it "leaves the query string unchanged when removing a missing parameter" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring missing: nil, a: 1")

      tag.render(Marten::Template::Tag::QueryStringSpec.context("x=y&a=1")).should eq "?x=y&amp;a=1"
    end

    it "keeps false and zero values" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring enabled: false, page: 0")

      tag.render(Marten::Template::Tag::QueryStringSpec.context).should eq "?enabled=false&amp;page=0"
    end

    it "url-encodes parameter names and values" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, %{querystring q: "hello world", next: "a&b"})

      tag.render(Marten::Template::Tag::QueryStringSpec.context).should eq "?q=hello+world&amp;next=a%26b"
    end

    it "expands array values and skips nil entries" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring color: colors")
      context = Marten::Template::Tag::QueryStringSpec.context
      context["colors"] = ["red", nil, "blue"]

      tag.render(context).should eq "?color=red&amp;color=blue"
    end

    it "removes a parameter when the array value is empty" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring color: colors")

      context = Marten::Template::Tag::QueryStringSpec.context("color=green&size=M")
      context["colors"] = [nil, nil]
      tag.render(context).should eq "?size=M"

      context["colors"] = [] of String
      tag.render(context).should eq "?size=M"
    end

    it "uses hash keys when a hash is passed as a parameter value" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring a: my_dict")
      context = Marten::Template::Tag::QueryStringSpec.context
      context["my_dict"] = {0 => 0, 1 => 2, 2 => 4}

      tag.render(context).should eq "?a=0&amp;a=1&amp;a=2"
    end

    it "resolves values from the context and applies filters" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring page: number|default:1")
      context = Marten::Template::Tag::QueryStringSpec.context("color=green")

      tag.render(context).should eq "?color=green&amp;page=1"

      context["number"] = 4
      tag.render(context).should eq "?color=green&amp;page=4"
    end

    it "does not escape the query string when auto escaping is disabled" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring")
      context = Marten::Template::Tag::QueryStringSpec.context("x=y&a=b")

      context.with_escape(false) do
        tag.render(context).should eq "?x=y&a=b"
      end
    end

    it "assigns the raw query string to a variable" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring page: 4 as next_page")
      context = Marten::Template::Tag::QueryStringSpec.context("color=blue&page=3")

      tag.render(context).should eq ""
      context["next_page"].should eq "?color=blue&page=4"
    end

    it "uses the handler request when the request context variable is absent" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring")
      context = Marten::Template::Context.new
      context.handler = Marten::Handler.new(Marten::Template::Tag::QueryStringSpec.request("a=b"))

      tag.render(context).should eq "?a=b"
    end

    it "prefers the request context variable over the handler request" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring")
      context = Marten::Template::Tag::QueryStringSpec.context("a=1")
      context.handler = Marten::Handler.new(Marten::Template::Tag::QueryStringSpec.request("b=2"))

      tag.render(context).should eq "?a=1"
    end

    it "raises when no request is available" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "The querystring tag requires an HTTP request in the template context"
      ) do
        tag.render(Marten::Template::Context.new)
      end
    end

    it "raises when the request context variable is not an HTTP request" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::QueryString.new(parser, "querystring")

      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "querystring requires the 'request' context variable to be an HTTP request (got String instead)"
      ) do
        tag.render(Marten::Template::Context{"request" => "nope"})
      end
    end

    it "can be rendered from a template" do
      template = Marten::Template::Template.new(%({% querystring size: "M" %}))

      template.render(Marten::Template::Tag::QueryStringSpec.context("color=green")).should eq "?color=green&amp;size=M"
    end
  end
end

module Marten::Template::Tag::QueryStringSpec
  def self.context(query : String = "")
    Marten::Template::Context{"request" => request(query)}
  end

  def self.request(query : String = "")
    resource = query.empty? ? "/" : "/?#{query}"
    Marten::HTTP::Request.new(
      ::HTTP::Request.new(
        method: "GET",
        resource: resource,
        headers: ::HTTP::Headers{"Host" => "example.com"}
      )
    )
  end
end
