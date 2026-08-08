require "./spec_helper"

module Marten
  module Handlers
    describe LiveReload do
      describe "#get" do
        it "sets up SSE response with correct headers" do
          request = HTTP::Request.new("GET", "/live-reload")
          handler = LiveReload.new(request)
          response = handler.dispatch

          response.content_type.should eq "text/event-stream"
          response.status.should eq 200
          response.headers["Cache-Control"].should eq "no-cache"
          response.headers["Connection"].should eq "keep-alive"
        end
      end

      describe ".broadcast" do
        it "allows broadcasting messages" do
          # Broadcasting should not raise errors
          LiveReload.broadcast("test-message")
        end
      end
    end
  end
end
