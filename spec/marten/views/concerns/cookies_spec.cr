require "./spec_helper"

describe Marten::Views::Cookies do
  describe "#cookies" do
    it "returns the request cookies store" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::CookiesSpec::TestView.new(request)
      view.cookies.should eq request.cookies
    end
  end
end

module Marten::Views::CookiesSpec
  class TestView
    include Marten::Views::Cookies

    getter request

    def initialize(@request : Marten::HTTP::Request)
    end
  end
end
