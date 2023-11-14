require "./spec_helper"
require "./generator_spec/app"

describe Marten::CLI::Generator do
  with_installed_apps Marten::CLI::GeneratorSpec::App

  around_each do |t|
    Marten::CLI::GeneratorSpec.empty_app_path

    t.run

    Marten::CLI::GeneratorSpec.empty_app_path
  end

  describe "::footer_description" do
    it "returns nil by default" do
      Marten::CLI::GeneratorSpec::EmptyGenerator.footer_description.should be_nil
    end

    it "returns the specified footer description" do
      Marten::CLI::GeneratorSpec::SimpleGenerator.footer_description.should eq "This is a simple generator footer."
    end
  end

  describe "::footer_description(footer_description)" do
    it "allows to configure the footer description of the generator" do
      Marten::CLI::GeneratorSpec::SimpleGenerator.footer_description.should eq "This is a simple generator footer."
    end
  end

  describe "::generator_name" do
    it "returns a name generated from the class name if no generator name is explicitly specified" do
      Marten::CLI::GeneratorSpec::EmptyGenerator.generator_name.should eq "empty_generator"
    end

    it "returns the configured generator name" do
      Marten::CLI::GeneratorSpec::SimpleGenerator.generator_name.should eq "simple"
    end
  end

  describe "::generator_name(name)" do
    it "allows to configure the name of the generator" do
      Marten::CLI::GeneratorSpec::SimpleGenerator.generator_name.should eq "simple"
    end
  end

  describe "::help" do
    it "returns an empty string if no help text is specified" do
      Marten::CLI::GeneratorSpec::EmptyGenerator.help.should eq ""
    end

    it "returns the configured help text" do
      Marten::CLI::GeneratorSpec::SimpleGenerator.help.should eq "This is a simple generator."
    end
  end

  describe "::help(text)" do
    it "allows to configure the help text" do
      Marten::CLI::GeneratorSpec::SimpleGenerator.help.should eq "This is a simple generator."
    end
  end

  describe "::inherited" do
    it "registers generator subclasses" do
      Marten::CLI::Manage::Command::Gen.generator_registry.includes?(Marten::CLI::GeneratorSpec::EmptyGenerator).should(
        be_true
      )
    end
  end

  describe "#create_app_files" do
    it "creates top-level files under the specified app config location" do
      app_config = Marten.apps.get("cli_generator_spec_app")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      generator = Marten::CLI::GeneratorSpec::SimpleGenerator.new(command)
      generator.create_app_files(
        app_config,
        [
          {"test.txt", "Hello world"},
          {"test2.txt", "Hello world 2"},
        ]
      )

      File.read("#{__DIR__}/generator_spec/test.txt").should eq "Hello world"
      File.read("#{__DIR__}/generator_spec/test2.txt").should eq "Hello world 2"

      output = stdout.rewind.gets_to_end
      output.includes?("test.txt").should be_true
      output.includes?("test2.txt").should be_true
    end

    it "creates folders and underlying files under the specified app config location" do
      app_config = Marten.apps.get("cli_generator_spec_app")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      generator = Marten::CLI::GeneratorSpec::SimpleGenerator.new(command)
      generator.create_app_files(
        app_config,
        [
          {"foo/bar/test.txt", "Hello world"},
          {"foo/bar/test2.txt", "Hello world 2"},
        ]
      )

      File.read("#{__DIR__}/generator_spec/foo/bar/test.txt").should eq "Hello world"
      File.read("#{__DIR__}/generator_spec/foo/bar/test2.txt").should eq "Hello world 2"

      output = stdout.rewind.gets_to_end
      output.includes?("foo/bar/test.txt").should be_true
      output.includes?("foo/bar/test2.txt").should be_true
    end
  end

  describe "#create_spec_files" do
    with_main_app_location "#{__DIR__}/generator_spec/project/src"

    it "creates top-level files under the specified spec folder" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      generator = Marten::CLI::GeneratorSpec::SimpleGenerator.new(command)
      generator.create_spec_files(
        [
          {"test.txt", "Hello world"},
          {"test2.txt", "Hello world 2"},
        ]
      )

      File.read("#{__DIR__}/generator_spec/project/spec/test.txt").should eq "Hello world"
      File.read("#{__DIR__}/generator_spec/project/spec/test2.txt").should eq "Hello world 2"

      output = stdout.rewind.gets_to_end
      output.includes?("test.txt").should be_true
      output.includes?("test2.txt").should be_true
    end

    it "creates folders and underlying files under the spec folder" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      generator = Marten::CLI::GeneratorSpec::SimpleGenerator.new(command)
      generator.create_spec_files(
        [
          {"foo/bar/test.txt", "Hello world"},
          {"foo/bar/test2.txt", "Hello world 2"},
        ]
      )

      File.read("#{__DIR__}/generator_spec/project/spec/foo/bar/test.txt").should eq "Hello world"
      File.read("#{__DIR__}/generator_spec/project/spec/foo/bar/test2.txt").should eq "Hello world 2"

      output = stdout.rewind.gets_to_end
      output.includes?("foo/bar/test.txt").should be_true
      output.includes?("foo/bar/test2.txt").should be_true
    end
  end

  describe "#print_warnings" do
    it "prints nothing if the generator did not set any warnings" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      generator = Marten::CLI::GeneratorSpec::SimpleGenerator.new(command)

      generator.print_warnings

      output = stdout.rewind.gets_to_end
      output.should eq ""
    end

    it "prints the warnings set by the generator" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      generator = Marten::CLI::GeneratorSpec::SimpleGenerator.new(command)

      generator.warnings << "This is a warning"
      generator.warnings << "Foo bar"

      generator.print_warnings

      output = stdout.rewind.gets_to_end
      output.includes?("This is a warning").should be_true
      output.includes?("Foo bar").should be_true
    end
  end

  describe "#warnings" do
    it "returns an empty array of strings by default" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      generator = Marten::CLI::GeneratorSpec::SimpleGenerator.new(command)

      generator.warnings.should eq [] of String
    end

    it "returns the warnings set during the execution of the generator" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      generator = Marten::CLI::GeneratorSpec::SimpleGenerator.new(command)

      generator.warnings << "This is a warning"
      generator.warnings << "Foo bar"

      generator.warnings.should eq ["This is a warning", "Foo bar"]
    end
  end

  describe "#warnings=" do
    it "allows to set warning messages" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["secretkey"] of String,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      generator = Marten::CLI::GeneratorSpec::SimpleGenerator.new(command)

      generator.warnings << "This is a warning"
      generator.warnings << "Foo bar"

      generator.warnings.should eq ["This is a warning", "Foo bar"]
    end
  end
end

module Marten::CLI::GeneratorSpec
  class EmptyGenerator < Marten::CLI::Generator
    def self.app_config
      TestApp.new
    end

    def run : Nil
    end
  end

  class SimpleGenerator < Marten::CLI::Generator
    generator_name :simple
    help "This is a simple generator."
    footer_description "This is a simple generator footer."

    def self.app_config
      TestApp.new
    end

    def run : Nil
    end
  end

  def self.empty_app_path
    Dir.glob(File.join("#{__DIR__}/generator_spec/", "/**/*"))
      .reject(&.ends_with?("app.cr"))
      .map do |path|
        FileUtils.rm_rf(path)
      end
  end
end
