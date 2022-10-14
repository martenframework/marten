require "./spec_helper"

describe Marten::Handlers::Flash do
  describe "#flash" do
    it "returns the flash store" do
      flash_store = Marten::HTTP::FlashStore.new

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test/xyz?foo=bar&xyz=test&foo=baz",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      request.flash = flash_store

      handler = Marten::Handlers::FlashSpec::TestHandler.new(request)
      handler.flash.should eq flash_store
    end
  end
end

module Marten::Handlers::FlashSpec
  class TestHandler
    include Marten::Handlers::Flash

    getter request

    def initialize(@request : Marten::HTTP::Request)
    end
  end
end
