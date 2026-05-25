require "./spec_helper"
require "./gen_migrations_spec/**"

describe Marten::CLI::Manage::Command::GenMigrations do
  with_installed_apps(
    Marten::CLI::Manage::Command::GenMigrationsSpec::SyncedApp,
    Marten::CLI::Manage::Command::GenMigrationsSpec::UnsyncedApp
  )

  describe "#run" do
    it "exits with a zero status when no changes are detected and the --check option is used" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::GenMigrations.new(
        options: ["cli_manage_command_gen_migrations_spec_synced_app", "--check"] of String,
        stdout: stdout,
        stderr: IO::Memory.new,
        exit_raises: true
      )

      command.handle.should eq 0

      stdout.rewind.gets_to_end.should be_empty
    end

    it "exits with a non-zero status when changes are detected and the --check option is used" do
      stdout = IO::Memory.new
      migrations_path = Marten::CLI::Manage::Command::GenMigrationsSpec::UnsyncedApp.new.migrations_path

      command = Marten::CLI::Manage::Command::GenMigrations.new(
        options: ["cli_manage_command_gen_migrations_spec_unsynced_app", "--check"] of String,
        stdout: stdout,
        stderr: IO::Memory.new,
        exit_raises: true
      )

      command.handle.should eq 1

      stdout.rewind.gets_to_end.should be_empty
      (Dir.exists?(migrations_path) ? Dir.children(migrations_path).size : 0).should eq 0
    end

    it "shows planned migrations without writing files when the --dry-run option is used" do
      stdout = IO::Memory.new
      migrations_path = Marten::CLI::Manage::Command::GenMigrationsSpec::UnsyncedApp.new.migrations_path
      initial_migration_count = Dir.exists?(migrations_path) ? Dir.children(migrations_path).size : 0

      command = Marten::CLI::Manage::Command::GenMigrations.new(
        options: ["cli_manage_command_gen_migrations_spec_unsynced_app", "--dry-run"] of String,
        stdout: stdout,
        stderr: IO::Memory.new
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?("Planned migrations for app").should be_true
      output.includes?("Would create").should be_true
      (Dir.exists?(migrations_path) ? Dir.children(migrations_path).size : 0).should eq initial_migration_count
    end

    it "shows planned migrations and exits with a non-zero status when both --dry-run and --check are used" do
      stdout = IO::Memory.new

      command = Marten::CLI::Manage::Command::GenMigrations.new(
        options: ["cli_manage_command_gen_migrations_spec_unsynced_app", "--dry-run", "--check"] of String,
        stdout: stdout,
        stderr: IO::Memory.new,
        exit_raises: true
      )

      command.handle.should eq 1

      output = stdout.rewind.gets_to_end
      output.includes?("Would create").should be_true
    end

    it "does not write migration files when the --check option is used" do
      migrations_path = Marten::CLI::Manage::Command::GenMigrationsSpec::UnsyncedApp.new.migrations_path
      initial_migration_count = Dir.exists?(migrations_path) ? Dir.children(migrations_path).size : 0

      command = Marten::CLI::Manage::Command::GenMigrations.new(
        options: ["cli_manage_command_gen_migrations_spec_unsynced_app", "--check"] of String,
        stdout: IO::Memory.new,
        stderr: IO::Memory.new,
        exit_raises: true
      )

      command.handle.should eq 1

      (Dir.exists?(migrations_path) ? Dir.children(migrations_path).size : 0).should eq initial_migration_count
    end
  end
end
