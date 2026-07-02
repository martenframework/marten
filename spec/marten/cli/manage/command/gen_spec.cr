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

    it "shows the generator warnings at the end of the generator execution" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["withwarnings"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("This is a warning").should be_true
      output.includes?("Foo bar").should be_true
    end
  end

  describe "#show_usage" do
    it "shows the gen command usage when no generator is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::Gen.new(options: ["-h"], stdin: stdin, stdout: stdout, exit_raises: true)
      command.handle

      output = stdout.rewind.gets_to_end.chomp("\n")

      output.includes?("Usage: marten gen [options] [generator] [arguments]").should be_true
      output
        .includes?("Generate various structures, abstractions, and values within an existing project.")
        .should be_true
      output.includes?("Arguments:").should be_true
      output.lines.any? do |line|
        line.includes?("generator") && line.includes?("Name of the generator to use")
      end.should be_true
      output.includes?("Options:").should be_true

      Marten::CLI::Manage::Command::GenSpec::SHARED_OPTIONS.each do |name, description|
        output.lines.any? do |line|
          line.includes?(name) && line.includes?(description)
        end.should be_true
      end

      output.includes?("Available generators are listed below.").should be_true
    end

    it "shows the usage of the specific generator if a generator name is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["model", "-h"],
        stdin: stdin,
        stdout: stdout,
        exit_raises: true,
      )
      command.handle

      output = stdout.rewind.gets_to_end.chomp("\n")

      output.includes?("Usage: marten gen model [options] [name] [field_definitions]").should be_true
      output.includes?("Generate a model.").should be_true
      output.includes?("Arguments:").should be_true
      output.lines.any? do |line|
        line.includes?("name") && line.includes?("Name of the model to generate")
      end.should be_true
      output.lines.any? do |line|
        line.includes?("field_definitions") && line.includes?("Field definitions of the model to generate")
      end.should be_true
      output.includes?("Options:").should be_true

      Marten::CLI::Manage::Command::GenSpec::MODEL_OPTIONS.each do |name, description|
        output.lines.any? do |line|
          line.includes?(name) && line.includes?(description)
        end.should be_true
      end
    end

    it "shows the footer description if the specified generator defines one" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["model", "-h"],
        stdin: stdin,
        stdout: stdout,
        exit_raises: true,
      )
      command.handle

      output = stdout.rewind.gets_to_end.chomp("\n")

      output.includes?("Options:").should be_true

      Marten::CLI::Manage::Command::GenSpec::MODEL_OPTIONS.each do |name, description|
        output.lines.any? do |line|
          line.includes?(name) && line.includes?(description)
        end.should be_true
      end

      output.includes?("Description:").should be_true
      output.includes?("Generates a model with the specified name and field definitions.").should be_true
      output.includes?(
        "generated in the app specified by the --app option or in the main app if no app is"
      ).should be_true
    end
  end
end

module Marten::CLI::Manage::Command::GenSpec
  SHARED_OPTIONS = [
    {"--error-trace", "Show full error trace (if a compilation is involved)"},
    {"--log-level=level", "Set the log level (default to \"info\")"},
    {"--no-color", "Disable colored output"},
    {"-h, --help", "Show this help"},
  ]

  MODEL_OPTIONS = [
    {"--app=APP", "Target app where the model should be created"},
    {"--parent=PARENT", "Parent class name for the generated model"},
    {"--no-timestamps", "Do not include timestamp fields in the generated model"},
  ] + SHARED_OPTIONS

  class GeneratorWithWarnings < Marten::CLI::Generator
    generator_name :withwarnings
    help "This is a generator with warnings."

    def self.app_config
      TestApp.new
    end

    def run : Nil
      warnings << "This is a warning"
      warnings << "Foo bar"
    end
  end
end
