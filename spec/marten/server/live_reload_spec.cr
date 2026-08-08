require "./spec_helper"

module Marten
  describe Server::LiveReload do
    describe ".running?" do
      it "returns false by default" do
        Marten::Server::LiveReload.running?.should be_false
      end

      it "returns true when the server is started" do
        begin
          Marten::Server::LiveReload.start
          # Give watcher time to start
          sleep 0.1.seconds
          Marten::Server::LiveReload.running?.should be_true
        ensure
          Marten::Server::LiveReload.stop
        end
      end
    end

    describe ".start" do
      it "starts the file watcher with default patterns" do
        begin
          Marten::Server::LiveReload.start
          Marten::Server::LiveReload.running?.should be_true

          File.write("src/temp_test.cr", "# test")
          # Give the watcher time to detect the change
          sleep 0.1.seconds

          # Cleanup
          File.delete("src/temp_test.cr")
        ensure
          Marten::Server::LiveReload.stop
        end
      end

      it "starts the file watcher with custom patterns" do
        begin
          custom_patterns = ["custom/**/*.cr"]
          Dir.mkdir_p("custom")

          Marten::Server::LiveReload.start(custom_patterns)
          # Give watcher time to start
          sleep 0.1.seconds
          Marten::Server::LiveReload.running?.should be_true

          File.write("custom/temp_test.cr", "# test")
          # Give the watcher time to detect the change
          sleep 0.1.seconds

          # Cleanup
          File.delete("custom/temp_test.cr")
          Dir.delete("custom")
        ensure
          Marten::Server::LiveReload.stop
        end
      end
    end

    describe ".stop" do
      it "stops the file watcher" do
        Marten::Server::LiveReload.start
        Marten::Server::LiveReload.stop

        Marten::Server::LiveReload.running?.should be_false
      end
    end
  end
end
