require "./spec_helper"

describe Marten::Views::Flash do
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

      view = Marten::Views::FlashSpec::TestView.new(request)
      view.flash.should eq flash_store
    end
  end
end

module Marten::Views::FlashSpec
  class TestView
    include Marten::Views::Flash

    getter request

    def initialize(@request : Marten::HTTP::Request)
    end
  end
end
