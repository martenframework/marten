require "./spec_helper"
require "./generator_spec/app"

describe Marten::CLI::Generator do
  with_installed_apps Marten::CLI::GeneratorSpec::App

  around_each do |t|
    Marten::CLI::GeneratorSpec.empty_app_path

    t.run

    Marten::CLI::GeneratorSpec.empty_app_path
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
