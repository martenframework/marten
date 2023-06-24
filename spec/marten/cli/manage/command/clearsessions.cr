require "./spec_helper"

describe Marten::CLI::Manage::Command::ClearSessions do
  describe "#run" do
    it "warns the user that the deleted sessions can't be restored" do
      stdin = IO::Memory.new("")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::ClearSessions.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      stdout.rewind.gets_to_end.starts_with?(
        "All expired sessions will be removed.\n" \
        "These sessions can't be restored.\n" \
        "Do you want to continue [yes/no]?"
      ).should be_true
    end

    it "does not do anything if the user inputs that they does not want to proceed" do
      stdin = IO::Memory.new("no")
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::ClearSessions.new(
        options: [] of String,
        stdin: stdin,
        stdout: stdout
      )

      command.handle

      stdout.rewind.gets_to_end.should eq(
        "All expired sessions will be removed.\n" \
        "These sessions can't be restored.\n" \
        "Do you want to continue [yes/no]? " \
        "Cancelling...\n"
      )
    end
  end
end
