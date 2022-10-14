require "./spec_helper"

describe Marten::Handlers::Defaults::Debug::PageNotFound do
  describe "#dispatch" do
    it "returns a specific welcome page if the request path is the root" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::Defaults::Debug::PageNotFound.new(request)

      response = handler.dispatch
      response.status.should eq 200
      response.content_type.should eq "text/html"
      response.content.includes?("Welcome to Marten Framework!").should be_true
    end

    it "returns a not found page if the request path is not the root" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::Defaults::Debug::PageNotFound.new(request)

      response = handler.dispatch
      response.status.should eq 404
      response.content_type.should eq "text/html"
      response.content.includes?("Page not found").should be_true
    end
  end

  describe "#error" do
    it "returns nil if no error is set" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::Defaults::Debug::PageNotFound.new(request)

      handler.error.should be_nil
    end

    it "returns the expecterd error if an error is set" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      error = Exception.new("Not found!")

      handler = Marten::Handlers::Defaults::Debug::PageNotFound.new(request)
      handler.error = error

      handler.error.should eq error
    end
  end

  describe "#error=" do
    it "allows to set the associated not found error" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      error = Exception.new("Not found!")

      handler = Marten::Handlers::Defaults::Debug::PageNotFound.new(request)
      handler.error = error

      handler.error.should eq error
    end
  end
end
