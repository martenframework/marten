require "./spec_helper"

describe Marten::CLI::Manage::Command::New do
  describe "#run" do
    around_each do |t|
      FileUtils.rm_rf(Marten::CLI::Manage::Command::NewSpec::PATH)
      FileUtils.mkdir(Marten::CLI::Manage::Command::NewSpec::PATH)
      FileUtils.cd(Marten::CLI::Manage::Command::NewSpec::PATH) { t.run }
      FileUtils.rm_rf(Marten::CLI::Manage::Command::NewSpec::PATH)
    end

    it "prints an error if no project type is specified" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("You must specify a valid structure type ('project or 'app')").should be_true
    end

    it "prints an error if an invalid project type is specified" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["unknown"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("Unrecognized structure type, you must use 'project or 'app'").should be_true
    end

    it "prints an error when trying to create a project without specifying a name" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("You must specify a project or application name").should be_true
    end

    it "prints an error when trying to create an app without specifying a name" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("You must specify a project or application name").should be_true
    end

    it "creates a new project structure" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project"],
        stdout: stdout
      )

      command.handle

      [
        "config/initializers/.gitkeep",
        "config/settings/base.cr",
        "config/settings/development.cr",
        "config/settings/production.cr",
        "config/settings/test.cr",
        "config/routes.cr",
        "spec/spec_helper.cr",
        "src/cli.cr",
        "src/project.cr",
        "src/server.cr",
        "src/emails/.gitkeep",
        "src/handlers/.gitkeep",
        "src/migrations/.gitkeep",
        "src/models/.gitkeep",
        "src/schemas/.gitkeep",
        "src/templates/.gitkeep",
        ".gitignore",
        "manage.cr",
        "shard.yml",
      ].each do |path|
        File.exists?(File.join(".", "dummy_project", path)).should be_true
      end
    end

    it "creates a new app structure" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["app", "dummy_app"],
        stdout: stdout
      )

      command.handle

      [
        "app.cr",
        "cli.cr",
        "emails/.gitkeep",
        "handlers/.gitkeep",
        "migrations/.gitkeep",
        "models/.gitkeep",
        "schemas/.gitkeep",
        "templates/.gitkeep",
      ].each do |path|
        File.exists?(File.join(".", "dummy_app", path)).should be_true
      end
    end

    it "creates a new project structure in a custom directory using the --dir option" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project", "--dir=sub/custom"],
        stdout: stdout
      )

      command.handle

      [
        "config/initializers/.gitkeep",
        "config/settings/base.cr",
        "config/settings/development.cr",
        "config/settings/production.cr",
        "config/settings/test.cr",
        "config/routes.cr",
        "spec/spec_helper.cr",
        "src/cli.cr",
        "src/project.cr",
        "src/server.cr",
        "src/emails/.gitkeep",
        "src/handlers/.gitkeep",
        "src/migrations/.gitkeep",
        "src/models/.gitkeep",
        "src/schemas/.gitkeep",
        "src/templates/.gitkeep",
        ".gitignore",
        "manage.cr",
        "shard.yml",
      ].each do |path|
        File.exists?(File.join(".", "sub", "custom", path)).should be_true
      end
    end

    it "creates a new project structure in a custom directory using the -d option" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["project", "dummy_project", "-d", "sub/custom"],
        stdout: stdout
      )

      command.handle

      [
        "config/initializers/.gitkeep",
        "config/settings/base.cr",
        "config/settings/development.cr",
        "config/settings/production.cr",
        "config/settings/test.cr",
        "config/routes.cr",
        "spec/spec_helper.cr",
        "src/cli.cr",
        "src/project.cr",
        "src/server.cr",
        "src/emails/.gitkeep",
        "src/handlers/.gitkeep",
        "src/migrations/.gitkeep",
        "src/models/.gitkeep",
        "src/schemas/.gitkeep",
        "src/templates/.gitkeep",
        ".gitignore",
        "manage.cr",
        "shard.yml",
      ].each do |path|
        File.exists?(File.join(".", "sub", "custom", path)).should be_true
      end
    end

    it "creates a new app structure in a custom directory the --dir option" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["app", "dummy_app", "--dir=sub/custom"],
        stdout: stdout
      )

      command.handle

      [
        "app.cr",
        "cli.cr",
        "emails/.gitkeep",
        "handlers/.gitkeep",
        "migrations/.gitkeep",
        "models/.gitkeep",
        "schemas/.gitkeep",
        "templates/.gitkeep",
      ].each do |path|
        File.exists?(File.join(".", "sub", "custom", path)).should be_true
      end
    end

    it "creates a new app structure in a custom directory the -d option" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::New.new(
        options: ["app", "dummy_app", "-d", "sub/custom"],
        stdout: stdout
      )

      command.handle

      [
        "app.cr",
        "cli.cr",
        "emails/.gitkeep",
        "handlers/.gitkeep",
        "migrations/.gitkeep",
        "models/.gitkeep",
        "schemas/.gitkeep",
        "templates/.gitkeep",
      ].each do |path|
        File.exists?(File.join(".", "sub", "custom", path)).should be_true
      end
    end
  end
end

module Marten::CLI::Manage::Command::NewSpec
  PATH = "spec/marten/cli/manage/command/new_spec"
end
