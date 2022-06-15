require "./spec_helper"

describe Marten::Views::Session do
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

      view = Marten::Views::SessionSpec::TestView.new(request)
      view.session.should eq session_store
    end
  end
end

module Marten::Views::SessionSpec
  class TestView
    include Marten::Views::Session

    getter request

    def initialize(@request : Marten::HTTP::Request)
    end
  end
end
