require "./spec_helper"

describe Marten::CLI::Manage do
  describe "#run" do
    it "displays all the commands and their descriptions when the top-level usage is outputted" do
      output = Marten::CLI::ManageSpec.run_command

      [
        Marten::CLI::Manage::Command::Migrate,
        Marten::CLI::Manage::Command::New,
        Marten::CLI::Manage::Command::Serve,
      ].each do |c|
        output.includes?(c.command_name).should be_true
        output.includes?(c.help).should be_true
      end
    end

    it "displays all the command names and their aliases when the top-level usage is outputted" do
      output = Marten::CLI::ManageSpec.run_command

      [
        Marten::CLI::Manage::Command::Gen,
        Marten::CLI::Manage::Command::Serve,
      ].each do |c|
        c.command_aliases.each do |a|
          output.includes?(a).should be_true
        end
      end
    end

    it "does not display the same commands mulitple times when the top-level usage is outputted due to aliases" do
      output = Marten::CLI::ManageSpec.run_command

      output.scan(Marten::CLI::Manage::Command::Serve.help).size.should eq 1
    end

    it "supports invoking commands through their associated aliases" do
      output = Marten::CLI::ManageSpec.run_command(["s", "--help"])

      output.includes?("Usage: marten serve [options]").should be_true
      output.includes?(Marten::CLI::Manage::Command::Serve.help).should be_true
    end
  end
end

module Marten::CLI::ManageSpec
  def self.run_command(options = [] of String)
    invocation = if options.empty?
                   "Marten::CLI::Manage.new(options: [] of String).run"
                 else
                   "Marten::CLI::Manage.new(options: #{options.inspect}).run"
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
