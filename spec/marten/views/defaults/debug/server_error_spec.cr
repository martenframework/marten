require "./spec_helper"

describe Marten::Views::Defaults::Debug::ServerError do
  describe "#bind_error" do
    it "associates an exception to the server error view" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = Exception.new("Something bad happened!")

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(error)

      view.error.should eq error
    end
  end

  describe "#dispatch" do
    it "returns a server error page if the incoming request accepts HTML content" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(Exception.new("Something bad happened!"))
      response = view.dispatch
      response.status.should eq 500
      response.content_type.should eq "text/html"
      response.content.includes?("Something bad happened!").should be_true
    end

    it "returns a raw server error response if the incoming request does not accept HTML content" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "application/json"}
        )
      )

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(Exception.new("Something bad happened!"))
      response = view.dispatch
      response.status.should eq 500
      response.content_type.should eq "text/plain"
      response.content.includes?("Internal Server Error").should be_true
    end
  end
end
