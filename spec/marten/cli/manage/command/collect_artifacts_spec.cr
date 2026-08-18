require "./spec_helper"
require "./collect_artifacts_spec/**"

module Marten::CLI::Manage::Command::CollectArtifactsSpec
  BROKEN_SYMLINK_PATH = "spec/config/locales/broken.yml"
  CONFIG_LOCALE_PATH  = "spec/config/locales/collect_artifacts_spec.yml"
  DEST_PATH           = "spec/collect_artifacts"
  OUTSIDE_DIR         = File.join(Dir.tempdir, "marten_collect_artifacts_spec_outside")
  SYMLINK_TARGET_DIR  = File.join(Dir.tempdir, "marten_collect_artifacts_spec_symlink_target")
  SYMLINKED_DIR_PATH  = "spec/config/locales/symlinked"

  def self.clean : Nil
    FileUtils.rm_rf(DEST_PATH)
    FileUtils.rm_rf(OUTSIDE_DIR)
    FileUtils.rm_rf(SYMLINK_TARGET_DIR)
    File.delete(SYMLINKED_DIR_PATH) if File.symlink?(SYMLINKED_DIR_PATH)
    File.delete(BROKEN_SYMLINK_PATH) if File.symlink?(BROKEN_SYMLINK_PATH)
    File.delete(CONFIG_LOCALE_PATH) if File.exists?(CONFIG_LOCALE_PATH)
    Dir.delete("spec/config/locales") rescue nil
    Dir.delete("spec/config") rescue nil
  end

  def self.destination_path(path)
    File.join(DEST_PATH, path)
  end

  def self.prepare_project_locale : Nil
    FileUtils.mkdir_p(Path[CONFIG_LOCALE_PATH].dirname)
    File.write(CONFIG_LOCALE_PATH, <<-YAML)
      en:
        collect_artifacts_spec_project: Project
      YAML
  end
end

describe Marten::CLI::Manage::Command::CollectArtifacts do
  with_installed_apps(
    Marten::CLI::Manage::Command::CollectArtifactsSpec::AppWithArtifacts,
    Marten::CLI::Manage::Command::CollectArtifactsSpec::EmptyApp
  )

  with_main_app_location "#{__DIR__}/../../../../test_project"

  describe "#run" do
    before_each do
      Marten::CLI::Manage::Command::CollectArtifactsSpec.clean
      Marten::CLI::Manage::Command::CollectArtifactsSpec.prepare_project_locale
    end

    after_each do
      Marten::CLI::Manage::Command::CollectArtifactsSpec.clean
    end

    it "warns the user that files might be overwritten by default" do
      stdin = IO::Memory.new("n")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      stdout.rewind.gets_to_end.starts_with?(
        "Runtime artifacts will be collected into 'artifacts'.\n" \
        "Any existing files will be overwritten.\n" \
        "Do you want to continue [yes/no]?"
      ).should be_true
    end

    it "does not do anything if the user inputs that they do not want to proceed" do
      stdin = IO::Memory.new("no")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: ["--dest-path", Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH],
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      stdout.rewind.gets_to_end.should eq(
        "Runtime artifacts will be collected into " \
        "'#{Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH}'.\n" \
        "Any existing files will be overwritten.\n" \
        "Do you want to continue [yes/no]? " \
        "Cancelling...\n"
      )

      Dir.exists?(Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH).should be_false
    end

    it "copies the runtime artifacts as expected if the user inputs that they want to proceed" do
      stdin = IO::Memory.new("yes")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: ["--no-color", "--dest-path", Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH],
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("Collecting runtime artifacts:\n").should be_true
      output.includes?("Copying src/marten/locales/en.yml...").should be_true
      output.includes?("Copying config/locales/collect_artifacts_spec.yml...").should be_true
      output.includes?("Copying spec/test_project/templates/base.html...").should be_true
      output.includes?(
        "Copying spec/marten/cli/manage/command/collect_artifacts_spec/app_with_artifacts/templates/example.html..."
      ).should be_true

      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path("src/marten/locales/en.yml")
      ).should be_true
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
          "config/locales/collect_artifacts_spec.yml"
        )
      ).should be_true
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path("spec/test_project/locales/en.yml")
      ).should be_true
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path("spec/test_project/templates/base.html")
      ).should be_true
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
          "spec/marten/cli/manage/command/collect_artifacts_spec/app_with_artifacts/locales/en.yml"
        )
      ).should be_true
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
          "spec/marten/cli/manage/command/collect_artifacts_spec/app_with_artifacts/templates/example.html"
        )
      ).should be_true
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
          "spec/marten/cli/manage/command/collect_artifacts_spec/app_with_artifacts/templates/partials/nested.html"
        )
      ).should be_true
    end

    it "accepts 'y' as a confirmation that the user wants to proceed" do
      stdin = IO::Memory.new("y")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: ["--dest-path", Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH],
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path("src/marten/locales/en.yml")
      ).should be_true
    end

    it "accepts badly inputted 'yes' values as a confirmation that the user wants to proceed" do
      stdin = IO::Memory.new("YeS")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: ["--dest-path", Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH],
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path("src/marten/locales/en.yml")
      ).should be_true
    end

    it "does not prompt the user before collecting artifacts if the --no-input option is used" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: [
          "--no-input",
          "--dest-path",
          Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH,
        ],
        stdout: stdout
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("Do you want to continue").should be_false
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path("src/marten/locales/en.yml")
      ).should be_true
    end

    it "overwrites existing files in the destination directory" do
      destination_path = Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
        "spec/marten/cli/manage/command/collect_artifacts_spec/app_with_artifacts/templates/example.html"
      )
      FileUtils.mkdir_p(Path[destination_path].dirname)
      File.write(destination_path, "Old template")

      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: [
          "--no-input",
          "--app",
          "collect_artifacts_spec_app",
          "--dest-path",
          Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH,
        ],
        stdout: stdout
      )

      command.handle

      File.read(destination_path).should eq "Example template\n"
    end

    it "copies hidden files" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: [
          "--no-input",
          "--app",
          "collect_artifacts_spec_app",
          "--dest-path",
          Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH,
        ],
        stdout: stdout
      )

      command.handle

      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
          "spec/marten/cli/manage/command/collect_artifacts_spec/app_with_artifacts/locales/.hidden.yml"
        )
      ).should be_true
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
          "spec/marten/cli/manage/command/collect_artifacts_spec/app_with_artifacts/templates/.hidden.html"
        )
      ).should be_true
    end

    it "collects artifacts behind symlinked directories" do
      FileUtils.mkdir_p(Marten::CLI::Manage::Command::CollectArtifactsSpec::SYMLINK_TARGET_DIR)
      File.write(
        File.join(Marten::CLI::Manage::Command::CollectArtifactsSpec::SYMLINK_TARGET_DIR, "en.yml"),
        "en:\n  collect_artifacts_spec_symlinked: Symlinked\n"
      )
      File.symlink(
        Marten::CLI::Manage::Command::CollectArtifactsSpec::SYMLINK_TARGET_DIR,
        Marten::CLI::Manage::Command::CollectArtifactsSpec::SYMLINKED_DIR_PATH
      )

      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: [
          "--no-input",
          "--dest-path",
          Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH,
        ],
        stdout: stdout
      )

      command.handle

      File.read(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path("config/locales/symlinked/en.yml")
      ).should eq "en:\n  collect_artifacts_spec_symlinked: Symlinked\n"
    end

    it "exits with a non-zero status if an artifact cannot be copied" do
      File.symlink(
        File.join(Marten::CLI::Manage::Command::CollectArtifactsSpec::SYMLINK_TARGET_DIR, "missing.yml"),
        Marten::CLI::Manage::Command::CollectArtifactsSpec::BROKEN_SYMLINK_PATH
      )

      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: [
          "--no-input",
          "--dest-path",
          Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH,
        ],
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle.should eq 1

      stderr.rewind.gets_to_end.includes?("Could not copy").should be_true
    end

    it "collects artifacts for a specific application only if the --app option is used" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: [
          "--no-input",
          "--app",
          "collect_artifacts_spec_app",
          "--dest-path",
          Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH,
        ],
        stdout: stdout
      )

      command.handle

      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
          "spec/marten/cli/manage/command/collect_artifacts_spec/app_with_artifacts/locales/en.yml"
        )
      ).should be_true
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
          "spec/marten/cli/manage/command/collect_artifacts_spec/app_with_artifacts/templates/partials/nested.html"
        )
      ).should be_true
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path("src/marten/locales/en.yml")
      ).should be_false
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path(
          "config/locales/collect_artifacts_spec.yml"
        )
      ).should be_false
      File.exists?(
        Marten::CLI::Manage::Command::CollectArtifactsSpec.destination_path("spec/test_project/templates/base.html")
      ).should be_false
    end

    it "exits with a non-zero status if the specified app label is not associated with any existing app" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: ["--no-input", "--app", "unknown_app"],
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle.should eq 1

      stderr.rewind.gets_to_end.includes?(
        "Label 'unknown_app' is not associated with any installed apps"
      ).should be_true
    end

    it "exits with a non-zero status if an artifact lives outside the compilation root" do
      outside_dir = Marten::CLI::Manage::Command::CollectArtifactsSpec::OUTSIDE_DIR
      FileUtils.mkdir_p(File.join(outside_dir, "locales"))
      File.write(File.join(outside_dir, "locales", "en.yml"), <<-YAML)
        en:
          collect_artifacts_spec_outside: Outside
        YAML
      Marten::Apps::MainConfig.overridden_location = outside_dir

      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: [
          "--no-input",
          "--app",
          "main",
          "--dest-path",
          Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH,
        ],
        stdout: stdout,
        stderr: stderr,
        exit_raises: true
      )

      command.handle.should eq 1

      stderr.rewind.gets_to_end.includes?("outside the compilation root").should be_true
    end

    it "prints the expected message if no artifacts are found" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectArtifacts.new(
        options: [
          "--no-color",
          "--no-input",
          "--app",
          "collect_artifacts_spec_empty_app",
          "--dest-path",
          Marten::CLI::Manage::Command::CollectArtifactsSpec::DEST_PATH,
        ],
        stdout: stdout
      )

      command.handle

      stdout.rewind.gets_to_end.includes?("No artifacts to collect...").should be_true
    end
  end
end
