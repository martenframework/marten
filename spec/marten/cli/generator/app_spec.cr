require "./spec_helper"

describe Marten::CLI::Generator::App do
  around_each do |t|
    Marten::CLI::Generator::AppSpec.remove_project_dir
    Marten::CLI::Generator::AppSpec.copy_project_dir

    t.run

    Marten::CLI::Generator::AppSpec.remove_project_dir
  end

  describe "#run" do
    with_main_app_location "#{__DIR__}/app_spec/project/src/"

    it "creates the expected application structure" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      [
        "app.cr",
        "cli.cr",
        "routes.cr",
        "emails/.gitkeep",
        "handlers/.gitkeep",
        "migrations/.gitkeep",
        "models/.gitkeep",
        "schemas/.gitkeep",
        "templates/.gitkeep",
      ].each do |path|
        output.includes?("Creating spec/marten/cli/generator/app_spec/project/src/blog/#{path}... DONE").should be_true

        File.exists?(File.join("#{__DIR__}/app_spec/project/src/blog", path)).should(
          be_true,
          "File #{path} does not exist",
        )
      end
    end

    it "adds the expected application requirement to the project.cr file" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding application requirement... DONE")
        .should be_true

      File.read("#{__DIR__}/app_spec/project/src/project.cr").includes?(%{require "./blog/app"}).should be_true
    end

    it "adds the expected application requirement to the cli.cr file" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding application CLI requirement... DONE")
        .should be_true

      File.read("#{__DIR__}/app_spec/project/src/cli.cr").includes?(%{require "./blog/cli"}).should be_true
    end

    it "adds the application to the installed_apps setting" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding application to installed_apps setting... DONE")
        .should be_true

      File.read("#{__DIR__}/app_spec/project/config/settings/base.cr").includes?("Blog::App").should be_true
    end

    it "adds the application to the main routes map" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding app route to main routes map... DONE")
        .should be_true

      File.read("#{__DIR__}/app_spec/project/config/routes.cr")
        .includes?(%{path "/blog", Blog::ROUTES, name: "blog"})
        .should be_true
    end

    it "creates the expected application structure when the project contains the src/apps folder" do
      FileUtils.mkdir_p("#{__DIR__}/app_spec/project/src/apps")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      [
        "app.cr",
        "cli.cr",
        "routes.cr",
        "emails/.gitkeep",
        "handlers/.gitkeep",
        "migrations/.gitkeep",
        "models/.gitkeep",
        "schemas/.gitkeep",
        "templates/.gitkeep",
      ].each do |path|
        output.includes?("Creating spec/marten/cli/generator/app_spec/project/src/apps/blog/#{path}... DONE")
          .should be_true

        File.exists?(File.join("#{__DIR__}/app_spec/project/src/apps/blog", path)).should(
          be_true,
          "File #{path} does not exist",
        )
      end
    end

    it "adds the expected application requirement to project.cr when the project contains the src/apps folder" do
      FileUtils.mkdir_p("#{__DIR__}/app_spec/project/src/apps")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding application requirement... DONE")
        .should be_true

      File.read("#{__DIR__}/app_spec/project/src/project.cr").includes?(%{require "./apps/blog/app"}).should be_true
    end

    it "adds the expected application requirement to the cli.cr file when the project contains the src/apps folder" do
      FileUtils.mkdir_p("#{__DIR__}/app_spec/project/src/apps")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding application CLI requirement... DONE")
        .should be_true

      File.read("#{__DIR__}/app_spec/project/src/cli.cr").includes?(%{require "./apps/blog/cli"}).should be_true
    end

    it "adds the application to the installed_apps setting when the project contains the src/apps folder" do
      FileUtils.mkdir_p("#{__DIR__}/app_spec/project/src/apps")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding application to installed_apps setting... DONE")
        .should be_true

      File.read("#{__DIR__}/app_spec/project/config/settings/base.cr").includes?("Blog::App").should be_true
    end

    it "adds the application to the main routes map when the project contains the src/apps folder" do
      FileUtils.mkdir_p("#{__DIR__}/app_spec/project/src/apps")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")
        .includes?("Adding app route to main routes map... DONE")
        .should be_true

      File.read("#{__DIR__}/app_spec/project/config/routes.cr")
        .includes?(%{path "/blog", Blog::ROUTES, name: "blog"})
        .should be_true
    end

    it "skips the addition of the requirement to the project.cr file if the project.cr file does not exist" do
      FileUtils.rm("#{__DIR__}/app_spec/project/src/project.cr")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding application requirement... SKIPPED").should be_true
      output.includes?("Could not add application requirement to project.cr file (file not found)").should be_true
    end

    it "skips the addition of the requirement to the cli.cr file if the cli.cr file does not exist" do
      FileUtils.rm("#{__DIR__}/app_spec/project/src/cli.cr")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding application CLI requirement... SKIPPED").should be_true
      output.includes?("Could not add application requirement to cli.cr file (file not found)").should be_true
    end

    it "skips the addition of the app to the installed_apps setting if the setting file does not exist" do
      FileUtils.rm("#{__DIR__}/app_spec/project/config/settings/base.cr")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding application to installed_apps setting... SKIPPED").should be_true
      output.includes?("Could not add application to installed_apps setting (setting file not found)").should be_true
    end

    it "skips the addition of the app to the installed_apps setting if the setting is not found" do
      File.write("#{__DIR__}/app_spec/project/config/settings/base.cr", "")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding application to installed_apps setting... SKIPPED").should be_true
      output.includes?("Could not add application to installed_apps setting (setting not found)").should be_true
    end

    it "skips the addition of the path to the main routes map if the routes file does not exist" do
      FileUtils.rm("#{__DIR__}/app_spec/project/config/routes.cr")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding app route to main routes map... SKIPPED").should be_true
      output.includes?("Could not add app route to main routes map (no config/routes.cr file)").should be_true
    end

    it "skips the addition of the path to the main routes map if no routes map block is found" do
      File.write("#{__DIR__}/app_spec/project/config/routes.cr", "")

      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "blog"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      output = stdout.rewind.gets_to_end.gsub(/\e\[([;\d]+)?m/, "")

      output.includes?("Adding app route to main routes map... SKIPPED").should be_true
      output.includes?("Could not add app route to main routes map (no routes map block found)").should be_true
    end

    it "returns an error if no application label is specified" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("An application label must be specified").should be_true
    end

    it "returns an error if the specified app label is invalid" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", "Invalid::App::Label"],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?(
        "Invalid application label - App labels can only contain lowercase letters and underscores"
      ).should be_true
    end

    it "returns an error if an application with the same label already exists" do
      stdin = IO::Memory.new
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      command = Marten::CLI::Manage::Command::Gen.new(
        options: ["app", TestApp.label],
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle

      stderr.rewind.gets_to_end.includes?("An application with the same label already exists").should be_true
    end
  end
end

module Marten::CLI::Generator::AppSpec
  def self.remove_project_dir
    FileUtils.rm_rf("#{__DIR__}/app_spec/project/")
  end

  def self.copy_project_dir
    FileUtils.cp_r("#{__DIR__}/app_spec/project_starting_point/", "#{__DIR__}/app_spec/project/")
  end
end
