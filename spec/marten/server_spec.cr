require "./spec_helper"

describe Marten::Server do
  describe "#handlers" do
    it "returns the expected handlers in non-debug mode" do
      with_overridden_setting("debug", false) do
        Marten::Server.handlers.size.should eq 5

        Marten::Server.handlers[0].should be_a HTTP::ErrorHandler
        Marten::Server.handlers[1].should be_a Marten::Server::Handlers::Logger
        Marten::Server.handlers[2].should be_a Marten::Server::Handlers::Error
        Marten::Server.handlers[3].should be_a Marten::Server::Handlers::Middleware
        Marten::Server.handlers[4].should be_a Marten::Server::Handlers::Routing
      end
    end

    it "returns the expected handlers in debug mode" do
      with_overridden_setting("debug", true) do
        Marten::Server.handlers.size.should eq 5

        Marten::Server.handlers[0].should be_a HTTP::ErrorHandler
        Marten::Server.handlers[1].should be_a Marten::Server::Handlers::DebugLogger
        Marten::Server.handlers[2].should be_a Marten::Server::Handlers::Error
        Marten::Server.handlers[3].should be_a Marten::Server::Handlers::Middleware
        Marten::Server.handlers[4].should be_a Marten::Server::Handlers::Routing
      end
    end
  end
end
