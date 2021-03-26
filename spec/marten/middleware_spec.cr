require "./spec_helper"

describe Marten::Middleware do
  describe "#process_request" do
    it "does nothing and returns nil by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      middleware = Marten::Middleware.new
      middleware.process_request(request).should be_nil
    end
  end

  describe "#process_response" do
    it "does nothing and returns the passed response by default" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      response = Marten::HTTP::Response.new(
        content: "It works!",
        content_type: "text/plain",
        status: 201
      )

      middleware = Marten::Middleware.new
      middleware.process_response(request, response).should eq response
    end
  end
end
