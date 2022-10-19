require "./spec_helper"

describe Marten do
  describe "#assets" do
    it "returns the assets engine" do
      Marten.assets.should be_a Marten::Asset::Engine
    end
  end

  describe "#start" do
    it "starts the server using the configured host and port" do
      MartenSpec.run_server.includes?(
        "Marten running on http://#{Marten.settings.host}:#{Marten.settings.port}"
      ).should be_true
    end

    it "starts the server using specific host and port ARGV arguments" do
      MartenSpec.run_server(%{Marten.start(args: ["-b 0.0.0.0", "-p 3000"])}).includes?(
        "Marten running on http://0.0.0.0:3000"
      ).should be_true
    end

    it "starts the server using specific host and port arguments" do
      MartenSpec.run_server(%{Marten.start(host: "0.0.0.0", port: 3000)}).includes?(
        "Marten running on http://0.0.0.0:3000"
      ).should be_true
    end
  end
end

module MartenSpec
  def self.run_server(code = "Marten.start")
    full_code = <<-CR
      require "./src/marten"
      #{code}
    CR

    stdout = IO::Memory.new
    stderr = IO::Memory.new

    process = Process.new("crystal", ["eval"], input: IO::Memory.new(full_code), output: stdout, error: stderr)
    sleep 5
    process.signal(Signal::INT)

    stdout.rewind.to_s
  end
end
