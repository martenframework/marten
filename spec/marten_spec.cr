require "./spec_helper"

describe Marten do
  describe "#assets" do
    it "returns the assets engine" do
      Marten.assets.should be_a Marten::Asset::Engine
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
