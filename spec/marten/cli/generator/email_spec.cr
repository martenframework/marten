require "./spec_helper"
require "./email_spec/other_app/app"

describe Marten::CLI::Generator::Email do
  around_each do |t|
    Marten::CLI::Generator::EmailSpec.empty_main_app_path
    Marten::CLI::Generator::EmailSpec.empty_other_app_path

    t.run

    Marten::CLI::Generator::EmailSpec.empty_main_app_path
    Marten::CLI::Generator::EmailSpec.empty_other_app_path
  end

  describe "#run" do
    context "when targetting the main application" do
      with_main_app_location "#{__DIR__}/email_spec/main_app/"

      it "generates the expected email files" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new
        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["email", "TestEmail"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        [
          "emails/test_email.cr",
          "templates/emails/test_email.html",
          "templates/emails/test_email.txt",
        ].each do |path|
          File.exists?(File.join("#{__DIR__}/email_spec/main_app/", path)).should be_true, "File #{path} does not exist"
        end
      end
    end

    context "when targetting a specific application" do
      with_installed_apps Marten::CLI::Generator::EmailSpec::App

      it "generates the expected email files" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new

        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["email", "TestEmail", "--app=cli_generator_email_spec_other_app"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        [
          "emails/test_email.cr",
          "templates/cli_generator_email_spec_other_app/emails/test_email.html",
          "templates/cli_generator_email_spec_other_app/emails/test_email.txt",
        ].each do |path|
          File.exists?(File.join("#{__DIR__}/email_spec/other_app/", path))
            .should be_true, "File #{path} does not exist"
        end
      end

      it "append an Email suffix to the email name automatically" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new

        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["email", "Test", "--app=cli_generator_email_spec_other_app"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        [
          "emails/test_email.cr",
          "templates/cli_generator_email_spec_other_app/emails/test_email.html",
          "templates/cli_generator_email_spec_other_app/emails/test_email.txt",
        ].each do |path|
          File.exists?(File.join("#{__DIR__}/email_spec/other_app/", path))
            .should be_true, "File #{path} does not exist"
        end

        File.read(File.join("#{__DIR__}/email_spec/other_app/emails/test_email.cr"))
          .includes?("class Marten::CLI::Generator::EmailSpec::TestEmail < Marten::Email").should be_true
      end

      it "uses the specified parent class" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new

        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["email", "TestEmail", "--app=cli_generator_email_spec_other_app", "--parent=ParentEmail"],
          stdin: stdin,
          stdout: stdout,
          stderr: stderr
        )

        command.handle

        [
          "emails/test_email.cr",
          "templates/cli_generator_email_spec_other_app/emails/test_email.html",
          "templates/cli_generator_email_spec_other_app/emails/test_email.txt",
        ].each do |path|
          File.exists?(File.join("#{__DIR__}/email_spec/other_app/", path))
            .should be_true, "File #{path} does not exist"
        end

        File.read(File.join("#{__DIR__}/email_spec/other_app/emails/test_email.cr"))
          .includes?("class Marten::CLI::Generator::EmailSpec::TestEmail < ParentEmail").should be_true
      end

      it "prints the expected error message and exit if the application does not exist" do
        stdin = IO::Memory.new
        stdout = IO::Memory.new
        stderr = IO::Memory.new

        command = Marten::CLI::Manage::Command::Gen.new(
          options: ["email", "Test", "--app=unknown"],
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

    it "outputs the expected error if no email name is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["email"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("An email name must be specified").should be_true
    end

    it "outputs the expected error if the specified email name is not CamelCase" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["email", "test_email"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("The email name must be CamelCase").should be_true
    end
  end
end

module Marten::CLI::Generator::EmailSpec
  def self.empty_main_app_path
    Dir.glob(File.join("#{__DIR__}/email_spec/main_app/", "/**/*")).map do |path|
      FileUtils.rm_rf(path)
    end
  end

  def self.empty_other_app_path
    Dir.glob(File.join("#{__DIR__}/email_spec/other_app/", "/**/*"))
      .reject(&.ends_with?("app.cr"))
      .map do |path|
        FileUtils.rm_rf(path)
      end
  end
end
