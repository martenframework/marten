require "./spec_helper"

describe Marten::CLI::Manage::Command::Version do
  describe "#run" do
    it "prints the Marten version as expected" do
      stdin = IO::Memory.new("n")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::Version.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      stdout.rewind.gets_to_end.strip.should eq "Marten #{Marten::VERSION}"
    end
  end
end
