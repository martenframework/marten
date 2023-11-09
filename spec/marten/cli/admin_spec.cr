require "./spec_helper"

describe Marten::CLI::Admin do
  describe "#run" do
    context "outside of a project" do
      around_each do |t|
        FileUtils.rm_rf(Marten::CLI::AdminSpec::NEW_PROJECT_PATH)
        FileUtils.mkdir_p(Marten::CLI::AdminSpec::NEW_PROJECT_PATH)
        t.run
        FileUtils.rm_rf(Marten::CLI::AdminSpec::NEW_PROJECT_PATH)
      end

      it "calls the new management command when called with the expected arguments" do
        Marten::CLI::AdminSpec.run_outside_command(
          ["new", "project", "test_project", "--dir=#{Marten::CLI::AdminSpec::NEW_PROJECT_PATH}"]
        )

        [
          "config/settings/base.cr",
          "config/settings/development.cr",
          "config/settings/production.cr",
          "config/settings/test.cr",
          "config/routes.cr",
          "spec/spec_helper.cr",
          "src/project.cr",
          "src/server.cr",
          "manage.cr",
          "shard.yml",
        ].each do |path|
          File.exists?(File.join(".", Marten::CLI::AdminSpec::NEW_PROJECT_PATH, path)).should(
            be_true,
            "File #{path} does not exist"
          )
        end
      end

      it "shows the Marten version when called with \"version\"" do
        output = Marten::CLI::AdminSpec.run_outside_command(["version"])
        output.strip.should eq "Marten #{Marten::VERSION}"
      end

      it "shows the Marten version when called with \"--version\"" do
        output = Marten::CLI::AdminSpec.run_outside_command(["--version"])
        output.strip.should eq "Marten #{Marten::VERSION}"
      end

      it "shows the Marten version when called with \"-v\"" do
        output = Marten::CLI::AdminSpec.run_outside_command(["-v"])
        output.strip.should eq "Marten #{Marten::VERSION}"
      end

      it "shows the \"new\" command usage when called with --help" do
        output = Marten::CLI::AdminSpec.run_outside_command(["--help"])
        output.strip.includes?(Marten::CLI::Manage::Command::New.help).should be_true
      end

      it "shows the \"new\" command usage when called with -h" do
        output = Marten::CLI::AdminSpec.run_outside_command(["--help"])
        output.strip.includes?(Marten::CLI::Manage::Command::New.help).should be_true
      end

      it "shows the \"new\" command usage when called with other commands" do
        output = Marten::CLI::AdminSpec.run_outside_command(["unknown"])
        output.strip.includes?(Marten::CLI::Manage::Command::New.help).should be_true
      end
    end

    context "inside of a project" do
      around_each do |t|
        FileUtils.rm_rf(File.join(Marten::CLI::AdminSpec::EXISTING_PROJECT_PATH, "lib"))
        FileUtils.rm_rf(File.join(Marten::CLI::AdminSpec::EXISTING_PROJECT_PATH, "new_app"))

        FileUtils.ln_s(Path["lib"].expand.to_s, File.join(Marten::CLI::AdminSpec::EXISTING_PROJECT_PATH, "lib"))

        FileUtils.cd(Marten::CLI::AdminSpec::EXISTING_PROJECT_PATH) { t.run }

        FileUtils.rm_rf(File.join(Marten::CLI::AdminSpec::EXISTING_PROJECT_PATH, "lib"))
        FileUtils.rm_rf(File.join(Marten::CLI::AdminSpec::EXISTING_PROJECT_PATH, "new_app"))
      end

      it "supports creating new apps by using the \"new\" management command" do
        Marten::CLI::AdminSpec.run_inside_command(["new", "app", "new_app"])

        [
          "spec/spec_helper.cr",
          "src/new_app.cr",
          "src/new_app/app.cr",
          "src/new_app/cli.cr",
          "src/new_app/emails/.gitkeep",
          "src/new_app/handlers/.gitkeep",
          "src/new_app/migrations/.gitkeep",
          "src/new_app/models/.gitkeep",
          "src/new_app/routes.cr",
          "src/new_app/schemas/.gitkeep",
          "src/new_app/templates/.gitkeep",
          ".editorconfig",
          ".gitignore",
          "shard.yml",
        ].each do |path|
          File.exists?(File.join("new_app", path)).should be_true, "File #{path} does not exist"
        end
      end

      it "supports running the development server by using the \"serve\" management command" do
        output = Marten::CLI::AdminSpec.run_inside_command(["serve", "-h"])

        output.includes?("Usage: marten serve [options]").should be_true
        output.includes?(Marten::CLI::Manage::Command::Serve.help).should be_true
      end

      it "supports running the development server by using the \"s\" management command alias" do
        output = Marten::CLI::AdminSpec.run_inside_command(["serve", "-h"])

        output.includes?("Usage: marten serve [options]").should be_true
        output.includes?(Marten::CLI::Manage::Command::Serve.help).should be_true
      end

      it "builds and runs the manage.cr CLI for other commands" do
        output = Marten::CLI::AdminSpec.run_inside_command(["other"])

        output.includes?("manage.cr was executed").should be_true
      end
    end
  end
end

module Marten::CLI::AdminSpec
  EXISTING_PROJECT_PATH = "spec/marten/cli/admin_spec/existing_project"
  NEW_PROJECT_PATH      = "spec/marten/cli/admin_spec/new_project"

  def self.run_inside_command(options = [] of String)
    invocation = if options.empty?
                   "Marten::CLI::Admin.new(options: [] of String).run"
                 else
                   "Marten::CLI::Admin.new(options: #{options.inspect}).run"
                 end

    full_code = <<-CR
      require "../../../../../src/marten"
      require "../../../../../src/marten/cli"

      #{invocation}
    CR

    stdout = IO::Memory.new
    stderr = IO::Memory.new

    Process.run("crystal", ["eval"], input: IO::Memory.new(full_code), output: stdout, error: stderr)

    stdout.rewind.to_s
  end

  def self.run_outside_command(options = [] of String)
    invocation = if options.empty?
                   "Marten::CLI::Admin.new(options: [] of String).run"
                 else
                   "Marten::CLI::Admin.new(options: #{options.inspect}).run"
                 end

    full_code = <<-CR
      require "./src/marten"
      require "./src/marten/cli"

      #{invocation}
    CR

    stdout = IO::Memory.new
    stderr = IO::Memory.new

    Process.run("crystal", ["eval"], input: IO::Memory.new(full_code), output: stdout, error: stderr)

    stdout.rewind.to_s
  end
end
