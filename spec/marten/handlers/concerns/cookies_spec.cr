require "./spec_helper"

describe Marten::Handlers::Cookies do
  describe "#cookies" do
    it "returns the request cookies store" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      handler = Marten::Handlers::CookiesSpec::TestHandler.new(request)
      handler.cookies.should eq request.cookies
    end
  end
end

module Marten::Handlers::CookiesSpec
  class TestHandler
    include Marten::Handlers::Cookies

    getter request

    def initialize(@request : Marten::HTTP::Request)
    end
  end
end
