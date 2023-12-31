require "./spec_helper"

describe Marten::CLI::Generator::Auth do
  around_each do |t|
    Marten::CLI::Generator::AuthSpec.remove_project_dir
    Marten::CLI::Generator::AuthSpec.copy_project_dir

    t.run

    Marten::CLI::Generator::AuthSpec.remove_project_dir
  end

  describe "#run" do
    with_main_app_location "#{__DIR__}/auth_spec/project/src/"

    it "creates the expected application structure" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      Marten::CLI::Generator::AuthSpec.expected_files("auth").each do |path|
        File.exists?(File.join("#{__DIR__}/auth_spec/project", path)).should(
          be_true,
          "File #{path} does not exist",
        )
      end
    end

    it "creates the expected application structure if the project contains a src/apps/folder" do
      FileUtils.mkdir_p("#{__DIR__}/auth_spec/project/src/apps/")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      Marten::CLI::Generator::AuthSpec.expected_files("auth", apps_folder: true).each do |path|
        File.exists?(File.join("#{__DIR__}/auth_spec/project", path)).should(
          be_true,
          "File #{path} does not exist",
        )
      end
    end

    it "creates the expected application structure when a custom app label is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth", "my_auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      Marten::CLI::Generator::AuthSpec.expected_files("my_auth").each do |path|
        File.exists?(File.join("#{__DIR__}/auth_spec/project", path)).should(
          be_true,
          "File #{path} does not exist",
        )
      end
    end

    it "adds the marten-auth dependency to the shard.yml file" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding martenframework/marten-auth to shard.yml... DONE")
        .should be_true

      File.read("#{__DIR__}/auth_spec/project/shard.yml")
        .includes?("  marten_auth:\n    github: martenframework/marten-auth\n")
        .should be_true
    end

    it "adds the marten-auth dependency to a shard.yml file that does not have a dependencies object" do
      File.write("#{__DIR__}/auth_spec/project/shard.yml", "")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding martenframework/marten-auth to shard.yml... DONE")
        .should be_true

      File.read("#{__DIR__}/auth_spec/project/shard.yml")
        .includes?("dependencies:\n  marten_auth:\n    github: martenframework/marten-auth\n")
        .should be_true
    end

    it "skips adding the marten-auth dependency if the shard.yml file is not found" do
      FileUtils.rm("#{__DIR__}/auth_spec/project/shard.yml")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding martenframework/marten-auth to shard.yml... SKIPPED").should be_true
      output.includes?("Could not add marten-auth dependency (no shard.yml file)").should be_true
    end

    it "adds the marten-auth requirement to the src/project.cr file" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding marten-auth requirement... DONE")
        .should be_true

      File.read("#{__DIR__}/auth_spec/project/src/project.cr")
        .includes?(%{require "marten"\nrequire "marten_auth"\n})
        .should be_true
    end

    it "adds the marten-auth requirement to the src/project.cr file when it does not contain the marten requirement" do
      File.write("#{__DIR__}/auth_spec/project/src/project.cr", "")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding marten-auth requirement... DONE")
        .should be_true

      File.read("#{__DIR__}/auth_spec/project/src/project.cr")
        .includes?(%{require "marten"\nrequire "marten_auth"\n})
        .should be_true
    end

    it "skips adding the marten-auth requirement if the src/project.cr file is not found" do
      FileUtils.rm("#{__DIR__}/auth_spec/project/src/project.cr")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding marten-auth requirement... SKIPPED").should be_true
      output.includes?("Could not add marten-auth requirement to project.cr file (file not found)").should be_true
    end

    it "sets the auth user model setting" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth", "my_auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding user model setting... DONE")
        .should be_true

      File.read("#{__DIR__}/auth_spec/project/config/settings/base.cr")
        .includes?("\n  config.auth.user_model = MyAuth::User\n")
        .should be_true
    end

    it "skips setting the auth user model setting if the setting file is not found" do
      FileUtils.rm("#{__DIR__}/auth_spec/project/config/settings/base.cr")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth", "my_auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding user model setting... SKIPPED").should be_true
      output.includes?("Could not add user model setting (setting file not found)").should be_true
    end

    it "adds the auth middleware to the middleware setting" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth", "my_auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding auth middleware... DONE")
        .should be_true

      File.read("#{__DIR__}/auth_spec/project/config/settings/base.cr")
        .includes?("MartenAuth::Middleware")
        .should be_true
    end

    it "skips adding the auth middleware if the setting file is not found" do
      FileUtils.rm("#{__DIR__}/auth_spec/project/config/settings/base.cr")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth", "my_auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding auth middleware... SKIPPED").should be_true
      output.includes?("Could not add auth middleware (setting file not found)").should be_true
    end

    it "skips adding the auth middleware if the setting file does not contain the middleware setting" do
      File.write("#{__DIR__}/auth_spec/project/config/settings/base.cr", "")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["auth", "my_auth"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding auth middleware... SKIPPED").should be_true
      output.includes?("Could not add auth middleware (setting not found)").should be_true
    end
  end
end

module Marten::CLI::Generator::AuthSpec
  def self.remove_project_dir
    FileUtils.rm_rf("#{__DIR__}/auth_spec/project/")
  end

  def self.copy_project_dir
    FileUtils.cp_r("#{__DIR__}/auth_spec/project_starting_point/", "#{__DIR__}/auth_spec/project/")
  end

  def self.expected_files(app_label, apps_folder = false)
    EXPECTED_FILES.map { |f| f % {"app_label" => app_label, "apps_folder" => apps_folder ? "apps/" : ""} }
  end

  private EXPECTED_FILES = [
    "spec/apps/%{app_label}/emails/password_reset_email_spec.cr",
    "spec/apps/%{app_label}/emails/spec_helper.cr",
    "spec/apps/%{app_label}/handlers/concerns/require_anonymous_user_spec.cr",
    "spec/apps/%{app_label}/handlers/concerns/require_signed_in_user_spec.cr",
    "spec/apps/%{app_label}/handlers/concerns/spec_helper.cr",
    "spec/apps/%{app_label}/handlers/password_reset_confirm_handler_spec.cr",
    "spec/apps/%{app_label}/handlers/password_reset_initiate_handler_spec.cr",
    "spec/apps/%{app_label}/handlers/password_update_handler_spec.cr",
    "spec/apps/%{app_label}/handlers/profile_handler_spec.cr",
    "spec/apps/%{app_label}/handlers/sign_in_handler_spec.cr",
    "spec/apps/%{app_label}/handlers/sign_out_handler_spec.cr",
    "spec/apps/%{app_label}/handlers/sign_up_handler_spec.cr",
    "spec/apps/%{app_label}/handlers/spec_helper.cr",
    "spec/apps/%{app_label}/spec_helper.cr",
    "spec/apps/%{app_label}/schemas/password_reset_confirm_schema_spec.cr",
    "spec/apps/%{app_label}/schemas/password_reset_initiate_schema_spec.cr",
    "spec/apps/%{app_label}/schemas/password_update_schema_spec.cr",
    "spec/apps/%{app_label}/schemas/sign_in_schema_spec.cr",
    "spec/apps/%{app_label}/schemas/sign_up_schema_spec.cr",
    "spec/apps/%{app_label}/schemas/spec_helper.cr",
    "src/%{apps_folder}%{app_label}/emails/password_reset_email.cr",
    "src/%{apps_folder}%{app_label}/handlers/concerns/require_anonymous_user.cr",
    "src/%{apps_folder}%{app_label}/handlers/concerns/require_signed_in_user.cr",
    "src/%{apps_folder}%{app_label}/handlers/password_reset_confirm_handler.cr",
    "src/%{apps_folder}%{app_label}/handlers/password_reset_initiate_handler.cr",
    "src/%{apps_folder}%{app_label}/handlers/profile_handler.cr",
    "src/%{apps_folder}%{app_label}/handlers/sign_in_handler.cr",
    "src/%{apps_folder}%{app_label}/handlers/sign_out_handler.cr",
    "src/%{apps_folder}%{app_label}/handlers/sign_up_handler.cr",
    "src/%{apps_folder}%{app_label}/migrations/0001_create_%{app_label}_user_table.cr",
    "src/%{apps_folder}%{app_label}/models/user.cr",
    "src/%{apps_folder}%{app_label}/schemas/password_reset_confirm_schema.cr",
    "src/%{apps_folder}%{app_label}/schemas/password_reset_initiate_schema.cr",
    "src/%{apps_folder}%{app_label}/schemas/password_update_schema.cr",
    "src/%{apps_folder}%{app_label}/schemas/sign_in_schema.cr",
    "src/%{apps_folder}%{app_label}/schemas/sign_up_schema.cr",
    "src/%{apps_folder}%{app_label}/templates/%{app_label}/emails/password_reset.html",
    "src/%{apps_folder}%{app_label}/templates/%{app_label}/password_reset_confirm.html",
    "src/%{apps_folder}%{app_label}/templates/%{app_label}/password_reset_initiate.html",
    "src/%{apps_folder}%{app_label}/templates/%{app_label}/password_update.html",
    "src/%{apps_folder}%{app_label}/templates/%{app_label}/profile.html",
    "src/%{apps_folder}%{app_label}/templates/%{app_label}/sign_in.html",
    "src/%{apps_folder}%{app_label}/templates/%{app_label}/sign_up.html",
    "src/%{apps_folder}%{app_label}/app.cr",
    "src/%{apps_folder}%{app_label}/cli.cr",
    "src/%{apps_folder}%{app_label}/routes.cr",
  ]
end
