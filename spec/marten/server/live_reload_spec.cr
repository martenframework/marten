require "./spec_helper"
require "http/web_socket"

module Marten
  describe Server::LiveReload do
  describe ".running?" do
    it "returns false by default" do
      Marten::Server::LiveReload.running?.should be_false
    end

    it "returns true when the server is started" do
      begin
        Marten::Server::LiveReload.start
        Marten::Server::LiveReload.running?.should be_true
      ensure
        Marten::Server::LiveReload.stop
      end
    end
  end

  describe ".clients" do
    it "returns an empty array by default" do
      Marten::Server::LiveReload.clients.should be_empty
    end
  end

  describe ".start" do
    it "starts the WebSocket server with default options" do
      begin
        Marten::Server::LiveReload.start
        Marten::Server::LiveReload.running?.should be_true

        # Test WebSocket connection
socket = HTTP::WebSocket::Client.new("localhost", "/live_reload", 35729)
        socket.on_message do |message|
          message.should eq "reload"
          socket.close
        end

        # Trigger a reload
        Marten::Server::LiveReload.trigger_reload
      ensure
        Marten::Server::LiveReload.stop
      end
    end

    it "starts the WebSocket server with custom options" do
      begin
        custom_port = 35730
        Marten::Server::LiveReload.start(port: custom_port)
        Marten::Server::LiveReload.running?.should be_true

        # Test WebSocket connection
socket = HTTP::WebSocket::Client.new("localhost", "/live_reload", custom_port)
        socket.on_message do |message|
          message.should eq "reload"
          socket.close
        end

        # Trigger a reload
        Marten::Server::LiveReload.trigger_reload
      ensure
        Marten::Server::LiveReload.stop
      end
    end
  end

  describe ".stop" do
    it "stops the server and clears clients" do
      Marten::Server::LiveReload.start
      Marten::Server::LiveReload.stop

      Marten::Server::LiveReload.running?.should be_false
      Marten::Server::LiveReload.clients.should be_empty
    end
  end

  describe ".trigger_reload" do
    it "sends reload message to all connected clients" do
      messages_received = 0

      begin
        Marten::Server::LiveReload.start

        # Connect two clients
        socket1 = HTTP::WebSocket::Client.new("localhost", "/live_reload", 35729)
        socket1.on_message { |_| messages_received += 1 }

        socket2 = HTTP::WebSocket::Client.new("localhost", "/live_reload", 35729)
        socket2.on_message { |_| messages_received += 1 }

        # Allow time for connections to establish
        sleep 0.1

        # Trigger reload
        Marten::Server::LiveReload.trigger_reload

        # Allow time for messages to be received
        sleep 0.1

        messages_received.should eq 2
      ensure
        Marten::Server::LiveReload.stop
      end
    end
  end
end
end
