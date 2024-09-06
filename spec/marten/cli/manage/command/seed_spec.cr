require "./spec_helper"

describe Marten::CLI::Manage::Command::Seed do
  after_each do
    File.delete("./seed.cr") if File.exists?("./seed.cr")
  end

  describe "#run" do
    it "runs the default seed file when no custom path is provided" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      # Create a mock seed file to simulate seeding
      message = "Seeding..."
      File.write("./seed.cr", "puts \"#{message}\"")

      command = Marten::CLI::Manage::Command::Seed.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.handle
      output = stdout.rewind.gets_to_end

      output.includes?("Running seed file at ./seed.cr").should be_true
      output.includes?(message).should be_true
      stderr.rewind.gets_to_end.empty?.should be_true
    end

    it "runs the seed file from a custom path when provided" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      custom_seed_path = "./custom_seed.cr"
      message = "Custom seeding..."
      File.write(custom_seed_path, "puts \"#{message}\"")

      command = Marten::CLI::Manage::Command::Seed.new(
        options: ["--file", custom_seed_path],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end

      File.delete(custom_seed_path) if File.exists?(custom_seed_path)

      output.includes?("Running seed file at #{custom_seed_path}").should be_true
      output.includes?(message).should be_true
      stderr.rewind.gets_to_end.empty?.should be_true
    end

    it "generates a default seed file if none exists" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Seed.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      stdout.rewind.gets_to_end.includes?("Seed file not found at ./seed.cr").should be_true
      stdout.rewind.gets_to_end.includes?("Default seed file generated at ./seed.cr").should be_true

      # Check that the file was generated
      File.exists?("./seed.cr").should be_true
    end

    it "handles errors if the seed file fails to run" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      # Create a seed file with invalid content
      File.write("./seed.cr", "invalid_crystal_code")

      command = Marten::CLI::Manage::Command::Seed.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stderr.rewind.gets_to_end
      output.includes?("Error:").should be_true
    end
  end
end
