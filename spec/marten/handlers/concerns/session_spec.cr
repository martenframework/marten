require "./spec_helper"

describe Marten::Handlers::Session do
  describe "#session" do
    it "returns the session store" do
      session_store = Marten::HTTP::Session::Store::Cookie.new(nil)

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.session = session_store

      handler = Marten::Handlers::SessionSpec::TestHandler.new(request)
      handler.session.should eq session_store
    end
  end
end

module Marten::Handlers::SessionSpec
  class TestHandler
    include Marten::Handlers::Session

    getter request

    def initialize(@request : Marten::HTTP::Request)
    end
  end
end
