require "./spec_helper"

describe Marten::CLI::Manage::Command::Base do
  describe "::command_aliases" do
    it "returns an empty array by default" do
      Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.command_aliases.should be_empty
    end

    it "returns the configured command aliases if applicable" do
      Marten::CLI::Manage::Command::BaseSpec::TestCommand.command_aliases.should eq ["t", "tt"]
    end
  end

  describe "::command_aliases(*aliases)" do
    it "allows to configure command aliases" do
      Marten::CLI::Manage::Command::BaseSpec::TestCommand.command_aliases.should eq ["t", "tt"]
    end
  end

  describe "::command_name" do
    it "returns an automatically-generated command name if no one is defined" do
      Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.command_name.should eq "empty_command"
    end

    it "returns the configured command name if applicable" do
      Marten::CLI::Manage::Command::BaseSpec::TestCommand.command_name.should eq "test"
    end
  end

  describe "::command_name(name)" do
    it "allows to specify a custom command name" do
      Marten::CLI::Manage::Command::BaseSpec::TestCommand.command_name.should eq "test"
    end
  end

  describe "::help" do
    it "returns an empty string by default" do
      Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.help.should be_empty
    end

    it "returns the configured help description" do
      Marten::CLI::Manage::Command::BaseSpec::TestCommand.help.should eq "Do something"
    end
  end

  describe "::help(description)" do
    it "allows to specify a custom help description" do
      Marten::CLI::Manage::Command::BaseSpec::TestCommand.help.should eq "Do something"
    end
  end

  describe "#handle" do
    it "setups the commands and runs it" do
      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: ["value"])
      command.handle

      command.arg.should eq "Run with arg: value"
    end
  end

  describe "#on_argument" do
    it "allows to configure a new command argument" do
      other_arg = nil

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: ["value1", "value2"])
      command.setup

      command.on_argument("otherarg", "Other argument") do |v|
        other_arg = v
      end

      command.handle

      other_arg.should eq "value2"
    end
  end

  describe "#on_option" do
    it "allows to configure a new command option" do
      option_set = false

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: ["value1", "--option"])
      command.setup

      command.on_option("option", "Option") do
        option_set = true
      end

      command.handle

      option_set.should be_true
    end

    it "allows to configure a new command option with a short flag" do
      option_set = false

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: ["-o", "value1"])
      command.setup

      command.on_option("o", "option", "Option") do
        option_set = true
      end

      command.handle

      option_set.should be_true
    end
  end

  describe "#on_option_with_arg" do
    it "allows to configure a new command option with an argument" do
      arg = nil

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: ["--option=hello"])
      command.setup

      command.on_option_with_arg("option", :arg, "Option") do |v|
        arg = v
      end

      command.handle

      arg.should eq "hello"
    end

    it "allows to configure a new command option with a short flag and an associated argument" do
      arg = nil

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: ["-o", "hello"])
      command.setup

      command.on_option_with_arg("o", "option", :arg, "Option") do |v|
        arg = v
      end

      command.handle

      arg.should eq "hello"
    end
  end

  describe "#print" do
    it "allows to print a specific message to the output file descriptor" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: [] of String, stdout: stdout)
      command.setup

      command.print("Hello World!")

      stdout.rewind
      stdout.gets_to_end.should eq "Hello World!\n"
    end

    it "allows to print a specific message to the output file descriptor with a specific ending" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: [] of String, stdout: stdout)
      command.setup

      command.print("Hello World!", ending: "")

      stdout.rewind
      stdout.gets_to_end.should eq "Hello World!"
    end
  end

  describe "#print_error" do
    it "allows to print a specific message to the error file descriptor" do
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: [] of String, stderr: stderr)
      command.setup

      command.print_error("This is bad")

      stderr.rewind
      stderr.gets_to_end.should eq "\e[1mThis is bad\e[0m\n"
    end

    it "allows to print a specific message to the error file descriptor without color if the no-color flag is set" do
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: ["--no-color"], stderr: stderr)
      command.handle

      command.print_error("This is bad")

      stderr.rewind
      stderr.gets_to_end.should eq "This is bad\n"
    end
  end

  describe "#style" do
    it "allows to set fore, back, and mode styles" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: [] of String, stdout: stdout)
      command.setup

      command.print(command.style("Hello World!", fore: :light_blue, back: :dark_gray, mode: :bold))

      stdout.rewind
      stdout.gets_to_end.should eq "\e[94;100;1mHello World!\e[0m\n"
    end

    it "does nothing if the no-color flag is set" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: ["--no-color"], stdout: stdout)
      command.handle

      command.print("Hello World!")

      stdout.rewind
      stdout.gets_to_end.should eq "Hello World!\n"
    end
  end
end

module Marten::CLI::Manage::Command::BaseSpec
  class EmptyCommand < Marten::CLI::Manage::Command::Base
  end

  class TestCommand < Marten::CLI::Manage::Command::Base
    command_name "test"
    command_aliases "t", :tt
    help "Do something"

    @arg : String? = nil

    getter arg

    def setup
      on_argument(:arg, "Argument") { |v| @arg = v }
    end

    def run
      @arg = "Run with arg: #{@arg}"
    end
  end
end
