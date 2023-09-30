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

    it "returns the status code in case the exit_raises flag is set" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::ErroredCommand.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle.should eq 1

      stderr.rewind.gets_to_end.includes?("This is bad").should be_true
    end
  end

  describe "#handle!" do
    it "raises the expected exception in case the exit_raises flag is set" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::ErroredCommand.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      error = expect_raises(Marten::CLI::Manage::Errors::Exit) do
        command.handle!
      end

      error.code.should eq 1
      stderr.rewind.gets_to_end.includes?("This is bad").should be_true
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

  describe "#on_invalid_option" do
    it "allows to configure a callback for invalid options" do
      unknown_options = [] of String

      command = Marten::CLI::Manage::Command::BaseSpec::TestCommand.new(options: ["arg", "--opt1", "--opt2"])

      command.on_unknown_argument { }
      command.on_invalid_option do |v|
        unknown_options << v
      end

      command.handle

      unknown_options.should eq ["--opt1", "--opt2"]
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

  describe "#on_unknown_argument" do
    it "allows to configure a callback for unknown arguments" do
      unknown_args = [] of String

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: ["value1", "value2"])
      command.setup

      command.on_unknown_argument do |v|
        unknown_args << v
      end

      command.handle

      unknown_args.should eq ["value1", "value2"]
    end

    it "allows to configure a callback for unknown arguments and the name of the unknown arguments" do
      stdout = IO::Memory.new
      unknown_args = [] of String

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: ["value1", "value2"], stdout: stdout)
      command.setup

      command.on_unknown_argument(:args) do |v|
        unknown_args << v
      end

      command.handle

      unknown_args.should eq ["value1", "value2"]

      command.show_usage
      stdout.rewind.gets_to_end.includes?("args").should be_true
    end

    it "allows to configure a callback for unknown arguments and the name and description of the unknown arguments" do
      stdout = IO::Memory.new
      unknown_args = [] of String

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: ["value1", "value2"], stdout: stdout)
      command.setup

      command.on_unknown_argument(:args, "Unknown arguments") do |v|
        unknown_args << v
      end

      command.handle

      unknown_args.should eq ["value1", "value2"]

      command.show_usage

      output = stdout.rewind.gets_to_end
      output.includes?("args").should be_true
      output.includes?("Unknown arguments").should be_true
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

  describe "#show_usage" do
    it "produces the expected output for a command without any additional arguments and options" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: [] of String, stdout: stdout)
      command.handle

      command.show_usage

      stdout.rewind.gets_to_end.chomp("\n").should eq(
        <<-USAGE
        Usage: marten empty_command [options]

        Options:
            --error-trace                    Show full error trace (if a compilation is involved)
            --no-color                       Disable colored output
            -h, --help                       Show this help
        USAGE
      )
    end

    it "produces the expected output for a command with a single argument" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: [] of String, stdout: stdout)

      command.setup
      command.on_argument(:arg, "This is an argument") { }

      command.handle
      command.show_usage

      stdout.rewind.gets_to_end.chomp("\n").should eq(
        <<-USAGE
        Usage: marten empty_command [options] [arg]

        Arguments:
            arg                              This is an argument

        Options:
            --error-trace                    Show full error trace (if a compilation is involved)
            --no-color                       Disable colored output
            -h, --help                       Show this help
        USAGE
      )
    end

    it "produces the expected output for a command with multiple arguments" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: [] of String, stdout: stdout)

      command.setup
      command.on_argument(:arg1, "This is the first argument") { }
      command.on_argument(:arg2, "This is the second argument") { }

      command.handle
      command.show_usage

      stdout.rewind.gets_to_end.chomp("\n").should eq(
        <<-USAGE
        Usage: marten empty_command [options] [arg1] [arg2]

        Arguments:
            arg1                             This is the first argument
            arg2                             This is the second argument

        Options:
            --error-trace                    Show full error trace (if a compilation is involved)
            --no-color                       Disable colored output
            -h, --help                       Show this help
        USAGE
      )
    end

    it "produces the expected output for a command with a custom option" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: [] of String, stdout: stdout)

      command.setup
      command.on_argument(:arg1, "This is the first argument") { }
      command.on_argument(:arg2, "This is the second argument") { }
      command.on_option("option", "This is an option") { }

      command.handle
      command.show_usage

      stdout.rewind.gets_to_end.chomp("\n").should eq(
        <<-USAGE
        Usage: marten empty_command [options] [arg1] [arg2]

        Arguments:
            arg1                             This is the first argument
            arg2                             This is the second argument

        Options:
            --option                         This is an option
            --error-trace                    Show full error trace (if a compilation is involved)
            --no-color                       Disable colored output
            -h, --help                       Show this help
        USAGE
      )
    end

    it "produces the expected output for a command with a custom option with a short flag" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: [] of String, stdout: stdout)

      command.setup
      command.on_argument(:arg1, "This is the first argument") { }
      command.on_argument(:arg2, "This is the second argument") { }
      command.on_option("o", "option", "This is an option") { }

      command.handle
      command.show_usage

      stdout.rewind.gets_to_end.chomp("\n").should eq(
        <<-USAGE
        Usage: marten empty_command [options] [arg1] [arg2]

        Arguments:
            arg1                             This is the first argument
            arg2                             This is the second argument

        Options:
            -o, --option                     This is an option
            --error-trace                    Show full error trace (if a compilation is involved)
            --no-color                       Disable colored output
            -h, --help                       Show this help
        USAGE
      )
    end

    it "produces the expected output for a command with unknown arguments" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: [] of String, stdout: stdout)

      command.setup
      command.on_argument(:arg1, "This is the first argument") { }
      command.on_argument(:arg2, "This is the second argument") { }
      command.on_unknown_argument { }

      command.handle
      command.show_usage

      stdout.rewind.gets_to_end.chomp("\n").should eq(
        <<-USAGE
        Usage: marten empty_command [options] [arg1] [arg2] [arguments]

        Arguments:
            arg1                             This is the first argument
            arg2                             This is the second argument

        Options:
            --error-trace                    Show full error trace (if a compilation is involved)
            --no-color                       Disable colored output
            -h, --help                       Show this help
        USAGE
      )
    end

    it "produces the expected output for a command with unknown arguments associated with a name and description" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::BaseSpec::EmptyCommand.new(options: [] of String, stdout: stdout)

      command.setup
      command.on_argument(:arg1, "This is the first argument") { }
      command.on_argument(:arg2, "This is the second argument") { }
      command.on_unknown_argument(:args, "Custom arguments") { }

      command.handle
      command.show_usage

      stdout.rewind.gets_to_end.chomp("\n").should eq(
        <<-USAGE
        Usage: marten empty_command [options] [arg1] [arg2] [args]

        Arguments:
            arg1                             This is the first argument
            arg2                             This is the second argument
            args                             Custom arguments

        Options:
            --error-trace                    Show full error trace (if a compilation is involved)
            --no-color                       Disable colored output
            -h, --help                       Show this help
        USAGE
      )
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

  class ErroredCommand < Marten::CLI::Manage::Command::Base
    def run
      print_error_and_exit("This is bad")
    end
  end
end
