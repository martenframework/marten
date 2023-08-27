require "./spec_helper"

describe Marten::CLI::Manage::Command::Gen do
  describe "#handle" do
    it "shows the command usage if no generator is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::Gen.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output
        .includes?("Generate various structures, abstractions, and values within an existing project.")
        .should be_true

      Marten::CLI::Manage::Command::Gen.generator_registry.each do |generator|
        output.includes?(generator.generator_name).should be_true
      end
    end

    it "shows the command usage if the help is requested and no generator is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["--help"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output
        .includes?("Generate various structures, abstractions, and values within an existing project.")
        .should be_true
    end

    it "shows the expected usage if the help is requested and a generator is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey", "--help"],
        stdin: stdin,
        stdout: stdout,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?(Marten::CLI::Generator::SecretKey.help).should be_true
    end

    it "shows the expected error in case the specified generator is unknown" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["unknowngen"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stderr.rewind.gets_to_end
      output.includes?("Unknown generator 'unknowngen'").should be_true
    end

    it "runs the specified generator" do
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

      stderr.rewind.gets_to_end.should be_empty
      stdout.rewind.gets_to_end.should_not be_empty
    end
  end
end
