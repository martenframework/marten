require "./spec_helper"

describe Marten::CLI::Manage::Command::Routes do
  describe "#run" do
    it "displays top-level routes as expected" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Routes.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.run

      output = stdout.rewind.gets_to_end
      output.includes?("/dummy/<id:int>/and/<scope:slug>").should be_true
      output.includes?("[dummy_with_id_and_scope]").should be_true
    end

    it "displays nested routes involving a single namespace as expected" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Routes.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.run

      output = stdout.rewind.gets_to_end
      output.includes?("/nested-1/dummy/<id:int>").should be_true
      output.includes?("[nested_1:dummy_with_id]").should be_true
    end

    it "displays nested routes involving multiple namespaces as expected" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Routes.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.run

      output = stdout.rewind.gets_to_end
      output.includes?("/nested-1/nested-2/dummy/<id:int>").should be_true
      output.includes?("[nested_1:nested_2:dummy_with_id]").should be_true
    end
  end
end
