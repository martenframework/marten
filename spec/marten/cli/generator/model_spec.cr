require "./spec_helper"
require "./model_spec/other_app/app"

describe Marten::CLI::Generator::Model do
  around_each do |t|
    Marten::CLI::Generator::ModelSpec.empty_main_app_path
    Marten::CLI::Generator::ModelSpec.empty_other_app_path

    t.run

    Marten::CLI::Generator::ModelSpec.empty_main_app_path
    Marten::CLI::Generator::ModelSpec.empty_other_app_path
  end

  describe "#run" do
    context "when targetting the main application" do
      with_main_app_location "#{__DIR__}/model_spec/main_app/"

      it "generates the expected model file" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["model", "AuthorProfile", "name:string", "bio:text"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/model_spec/main_app/models/author_profile.cr")).should be_true,
          "Model file does not exist"

        model_content = File.read(File.join("#{__DIR__}/model_spec/main_app/models/author_profile.cr"))

        model_content.includes?("class AuthorProfile < Marten::Model").should be_true,
          "Model file does not contain the expected class name"
        model_content.includes?("field :id, :big_int, primary_key: true, auto: true").should be_true,
          "Model file does not contain the expected id field"
        model_content.includes?("field :name, :string, max_size: 255").should be_true,
          "Model file does not contain the expected name field"
        model_content.includes?("field :bio, :text").should be_true,
          "Model file does not contain the expected bio field"
        model_content.includes?("with_timestamp_fields").should be_true,
          "Model file does not contain the expected with_timestamp_fields call"
      end

      it "generates the expected model file when the --no-timestamps option is set" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["model", "AuthorProfile", "name:string", "bio:text", "--no-timestamps"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/model_spec/main_app/models/author_profile.cr")).should be_true,
          "Model file does not exist"

        model_content = File.read(File.join("#{__DIR__}/model_spec/main_app/models/author_profile.cr"))

        model_content.includes?("class AuthorProfile < Marten::Model").should be_true,
          "Model file does not contain the expected class name"
        model_content.includes?("field :id, :big_int, primary_key: true, auto: true").should be_true,
          "Model file does not contain the expected id field"
        model_content.includes?("field :name, :string, max_size: 255").should be_true,
          "Model file does not contain the expected name field"
        model_content.includes?("field :bio, :text").should be_true,
          "Model file does not contain the expected bio field"
        model_content.includes?("with_timestamp_fields").should be_false,
          "Model file should not contain a with_timestamp_fields call"
      end

      it "generates the expected model file when the --parent option is used" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["model", "AuthorProfile", "name:string", "bio:text", "--parent=FooBar"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/model_spec/main_app/models/author_profile.cr")).should be_true,
          "Model file does not exist"

        model_content = File.read(File.join("#{__DIR__}/model_spec/main_app/models/author_profile.cr"))

        model_content.includes?("class AuthorProfile < FooBar").should be_true,
          "Model file does not contain the expected class name"
        model_content.includes?("field :id, :big_int, primary_key: true, auto: true").should be_true,
          "Model file does not contain the expected id field"
        model_content.includes?("field :name, :string, max_size: 255").should be_true,
          "Model file does not contain the expected name field"
        model_content.includes?("field :bio, :text").should be_true,
          "Model file does not contain the expected bio field"
        model_content.includes?("with_timestamp_fields").should be_true,
          "Model file does not contain the expected with_timestamp_fields call"
      end
    end

    context "when targetting a specific application" do
      with_installed_apps Marten::CLI::Generator::ModelSpec::App

      it "generates the expected model file" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new

        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["model", "AuthorProfile", "name:string", "bio:text", "--app=cli_generator_model_spec_other_app"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        File.exists?(File.join("#{__DIR__}/model_spec/other_app/models/author_profile.cr")).should be_true,
          "Model file does not exist"

        model_content = File.read(File.join("#{__DIR__}/model_spec/other_app/models/author_profile.cr"))

        model_content.includes?("class Marten::CLI::Generator::ModelSpec::AuthorProfile < Marten::Model")
          .should be_true,
            "Model file does not contain the expected class name"
        model_content.includes?("field :id, :big_int, primary_key: true, auto: true").should be_true,
          "Model file does not contain the expected id field"
        model_content.includes?("field :name, :string, max_size: 255").should be_true,
          "Model file does not contain the expected name field"
        model_content.includes?("field :bio, :text").should be_true,
          "Model file does not contain the expected bio field"
        model_content.includes?("with_timestamp_fields").should be_true,
          "Model file does not contain the expected with_timestamp_fields call"
      end

      it "prints the expected error message and exit if the application does not exist" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new

        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["model", "AuthorProfile", "name:string", "bio:text", "--app=unknown"],
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

    it "outputs the expected error if no model name is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["model"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("A model name must be specified").should be_true
    end

    it "outputs the expected error if the specified model name is not CamelCase" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["model", "test_model"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("The model name must be CamelCase").should be_true
    end

    it "outputs the expected error if one of the field definitions is invalid" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["model", "AuthorProfile", "name:unknown"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stderr.rewind.gets_to_end

      output.includes?("'name:unknown' is not a valid field definition").should be_true
      output.includes?("The field type 'unknown' does not correspond to an existing field type.").should be_true
    end
  end
end

module Marten::CLI::Generator::ModelSpec
  def self.empty_main_app_path
    Dir.glob(File.join("#{__DIR__}/model_spec/main_app/", "/**/*")).map do |path|
      FileUtils.rm_rf(path)
    end
  end

  def self.empty_other_app_path
    Dir.glob(File.join("#{__DIR__}/model_spec/other_app/", "/**/*"))
      .reject(&.ends_with?("app.cr"))
      .map do |path|
        FileUtils.rm_rf(path)
      end
  end
end
