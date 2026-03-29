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

  describe "#setup" do
    around_each do |t|
      Marten::Server.instance.close
      Marten::Server.reset_instance

      t.run

      Marten::Server.instance.close
      Marten::Server.reset_instance
    end

    it "binds to TCP by default" do
      with_overridden_setting("host", "127.0.0.1") do
        with_overridden_setting("port", 8081) do
          Marten::Server.setup
          Marten::Server.addresses.first.should eq "http://127.0.0.1:8081"
        end
      end
    end

    it "binds to Unix socket when socket setting is configured" do
      socket_path = "/tmp/marten_test.sock"
      with_overridden_setting("socket", socket_path, nilable: true) do
        Marten::Server.setup
        Marten::Server.addresses.first.should eq "http://#{socket_path}"
      ensure
        File.delete(socket_path) if File.exists?(socket_path)
      end
    end
  end
end
