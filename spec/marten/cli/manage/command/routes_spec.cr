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

    it "displays localized routes as expected" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Routes.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.run

      output = stdout.rewind.gets_to_end
      output.includes?("/<locale>/dummy-localized").should be_true
      output.includes?("/<locale>/dummy-localized/<id:int>").should be_true
      output.includes?("/<locale>/dummy-localized/<id:int>/and/<scope:slug>").should be_true
      output.includes?("/<locale>/nested-1-localized/dummy/<id:int>").should be_true
      output.includes?("/<locale>/nested-1-localized/nested-2/dummy/<id:int>").should be_true
    end
  end

  describe "#handle" do
    it "only displays routes whose path matches the --grep option" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Routes.new(
        options: ["--grep=nested-2"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("/nested-1/nested-2/dummy/<id:int>").should be_true
      output.includes?("/dummy/<id:int>/and/<scope:slug>").should be_false
    end

    it "supports the -g short option" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Routes.new(
        options: ["-g", "nested-2"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("/nested-1/nested-2/dummy/<id:int>").should be_true
      output.includes?("/dummy/<id:int>/and/<scope:slug>").should be_false
    end

    it "matches the grep option in a case-insensitive way" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Routes.new(
        options: ["--grep=NESTED-2"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("/nested-1/nested-2/dummy/<id:int>").should be_true
    end

    it "also matches the grep option against the route name" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Routes.new(
        options: ["--grep=dummy_with_id_and_scope"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("[dummy_with_id_and_scope]").should be_true
      output.includes?("/nested-1/dummy/<id:int>").should be_false
    end

    it "prints a notice when no route matches the grep option" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Routes.new(
        options: ["--grep=totally-missing-route"],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?(%{No routes found matching "totally-missing-route".}).should be_true
    end
  end
end
