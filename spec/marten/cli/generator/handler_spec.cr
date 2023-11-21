require "./spec_helper"
require "./handler_spec/other_app/app"

describe Marten::CLI::Generator::Handler do
  around_each do |t|
    Marten::CLI::Generator::HandlerSpec.empty_main_app_path
    Marten::CLI::Generator::HandlerSpec.empty_other_app_path

    t.run

    Marten::CLI::Generator::HandlerSpec.empty_main_app_path
    Marten::CLI::Generator::HandlerSpec.empty_other_app_path
  end

  describe "#run" do
    context "when targetting the main application" do
      with_main_app_location "#{__DIR__}/handler_spec/main_app/"

      it "generates the expected handler file" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["handler", "TestHandler"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/handler_spec/main_app/handlers/test_handler.cr")).should be_true,
          "Handler file does not exist"

        handler_content = File.read(File.join("#{__DIR__}/handler_spec/main_app/handlers/test_handler.cr"))

        handler_content.includes?("class TestHandler < Marten::Handler").should be_true,
          "Handler file does not contain the expected class name"
      end
      it "appends the Handler suffix to the handler name if it's not present" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["handler", "Test"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/handler_spec/main_app/handlers/test_handler.cr")).should be_true,
          "Handler file does not exist"

        handler_content = File.read(File.join("#{__DIR__}/handler_spec/main_app/handlers/test_handler.cr"))

        handler_content.includes?("class TestHandler < Marten::Handler").should be_true,
          "Handler file does not contain the expected class name"
      end
    end

    context "when targetting a specific application" do
      with_installed_apps Marten::CLI::Generator::HandlerSpec::App

      it "generates the expected handler file" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["handler", "TestHandler", "--app=cli_generator_handler_spec_other_app"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/handler_spec/other_app/handlers/test_handler.cr")).should be_true,
          "Handler file does not exist"

        handler_content = File.read(File.join("#{__DIR__}/handler_spec/other_app/handlers/test_handler.cr"))

        handler_content.includes?(
          "class Marten::CLI::Generator::HandlerSpec::TestHandler < Marten::Handler"
        ).should be_true, "Handler file does not contain the expected class name"
      end

      it "generates the expected handler file when a parent class is specified" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["handler", "TestHandler", "--app=cli_generator_handler_spec_other_app", "--parent=OtherHandler"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr,
          exit_raises: true,
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/handler_spec/other_app/handlers/test_handler.cr")).should be_true,
          "Handler file does not exist"

        handler_content = File.read(File.join("#{__DIR__}/handler_spec/other_app/handlers/test_handler.cr"))

        handler_content.includes?(
          "class Marten::CLI::Generator::HandlerSpec::TestHandler < OtherHandler"
        ).should be_true, "Handler file does not contain the expected class name"
      end

      it "prints the expected error message and exit if the application does not exist" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new

        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["handler", "TestHandler", "--app=unknown"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr,
          exit_raises: true
        )

        exit_code = command.handle

        exit_code.should eq 1

        stderr.rewind.gets_to_end.includes?("Label 'unknown' is not associated with any installed apps").should be_true
      end
    end

    it "prints the expected error message if the handler name is not CamelCase" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["handler", "test_handler"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("The handler name must be CamelCase").should be_true
    end
  end
end

module Marten::CLI::Generator::HandlerSpec
  def self.empty_main_app_path
    Dir.glob(File.join("#{__DIR__}/handler_spec/main_app/", "/**/*")).map do |path|
      FileUtils.rm_rf(path)
    end
  end

  def self.empty_other_app_path
    Dir.glob(File.join("#{__DIR__}/handler_spec/other_app/", "/**/*"))
      .reject(&.ends_with?("app.cr"))
      .map do |path|
        FileUtils.rm_rf(path)
      end
  end
end
