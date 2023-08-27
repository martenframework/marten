require "./spec_helper"

describe Marten::CLI::Generator::SecretKey do
  describe "#run" do
    it "prints the generated secret key" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      (output.size >= 32).should be_true
    end
  end
end
