require "./spec_helper"

describe Marten::CLI::Manage::Command::CollectAssets do
  describe "#run" do
    before_each do
      FileUtils.rm_rf("spec/assets")
    end

    it "warns the user that files might be overwritten by default" do
      stdin = IO::Memory.new("n")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectAssets.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      stdout.rewind.gets_to_end.starts_with?(
        "Assets will be collected into the storage configured in your application settings.\n" \
        "Any existing files will be overwritten.\n" \
        "Do you want to continue [yes/no]?"
      ).should be_true
    end

    it "does not do anything if the user inputs that they does not want to proceed" do
      stdin = IO::Memory.new("no")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectAssets.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      stdout.rewind.gets_to_end.should eq(
        "Assets will be collected into the storage configured in your application settings.\n" \
        "Any existing files will be overwritten.\n" \
        "Do you want to continue [yes/no]? " \
        "Cancelling...\n"
      )

      File.exists?("spec/assets/css/test.css").should be_false
    end

    it "copies the assets as expected if the user inputs that they want to proceed" do
      stdin = IO::Memory.new("yes")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectAssets.new(
        options: ["--no-color"],
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("Collecting assets:\n").should be_true
      output.includes?("Copying css/test.css...").should be_true

      File.exists?("spec/assets/css/test.css").should be_true
    end

    it "accepts 'y' as a confirmation that the user wants to proceed" do
      stdin = IO::Memory.new("y")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectAssets.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      File.exists?("spec/assets/css/test.css").should be_true
    end

    it "accepts badly inputted 'yes' values as a confirmation that the user wants to proceed" do
      stdin = IO::Memory.new("YeS")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectAssets.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      File.exists?("spec/assets/css/test.css").should be_true
    end

    it "does not prompt the user before collecting assets if the --no-input option is used" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::CollectAssets.new(
        options: ["--no-input"],
        stdout: stdout
      )

      command.handle

      File.exists?("spec/assets/css/test.css").should be_true
    end
  end

  describe "#create_manifest_file" do
    with_main_app_location "#{__DIR__}/../../../../test_project"

    it "copies the assets as expected, adds a fingerprint and creates the correct mapping inside a manifest.json" do
      stdin = IO::Memory.new("yes")
      stdout = IO::Memory.new

      original_css_asset_path = "spec/test_project/assets/css/test.css"

      command = Marten::CLI::Manage::Command::CollectAssets.new(
        options: ["--no-color", "--no-input", "--fingerprint"],
        stdin: stdin,
        stdout: stdout
      )

      sha = Digest::MD5.new
      sha.file original_css_asset_path
      file_digest = sha.hexfinal[...12]

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("Copying css/test.css (#{file_digest})...").should be_true
      output.includes?("Creating spec/test_project/manifest.json...").should be_true

      File.exists?("spec/assets/css/test.#{file_digest}.css").should be_true
      File.exists?("spec/test_project/manifest.json").should be_true

      json = File.open("spec/src/manifest.json") do |file|
        JSON.parse(file)
      end

      manifest = json.as_h

      manifest.has_key?("css/test.css").should be_true
      manifest["css/test.css"].to_s.should eq "css/test.#{file_digest}.css"
    end

    it "copies the assets as expected, adds a fingerprint and creates the correct mapping inside a specified file" do
      stdin = IO::Memory.new("yes")
      stdout = IO::Memory.new

      original_css_asset_path = "spec/test_project/assets/css/test.css"
      manifest_path = "spec/test_project/collect/manifest.json"

      command = Marten::CLI::Manage::Command::CollectAssets.new(
        options: ["--no-color", "--no-input", "--fingerprint", "--manifest-path", manifest_path],
        stdin: stdin,
        stdout: stdout
      )

      sha = Digest::MD5.new
      sha.file original_css_asset_path
      file_digest = sha.hexfinal[...12]

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("Copying css/test.css (#{file_digest})...").should be_true
      output.includes?("Creating #{manifest_path}...").should be_true

      File.exists?("spec/assets/css/test.#{file_digest}.css").should be_true
      File.exists?("spec/src/manifest.json").should be_true

      json = File.open("spec/src/manifest.json") do |file|
        JSON.parse(file)
      end

      manifest = json.as_h

      manifest.has_key?("css/test.css").should be_true
      manifest["css/test.css"].to_s.should eq "css/test.#{file_digest}.css"
    end
  end
end
