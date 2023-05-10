require "./spec_helper"
require "./migrate_spec/**"

describe Marten::CLI::Manage::Command::Migrate do
  with_installed_apps(
    Marten::CLI::Manage::Command::MigrateSpec::FooApp,
    Marten::CLI::Manage::Command::MigrateSpec::BarApp
  )

  before_all do
    Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.default).setup
    Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.get(:other)).setup
  end

  after_all do
    Marten::DB::Management::Migrations::Record
      .filter(app__startswith: "cli_manage_command_migrate_spec_")
      .delete(raw: true)

    introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
    Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
      if introspector.table_names.includes?("cli_manage_command_migrate_spec_foo_tags")
        schema_editor.delete_table("cli_manage_command_migrate_spec_foo_tags")
      end

      if introspector.table_names.includes?("cli_manage_command_migrate_spec_bar_tags")
        schema_editor.delete_table("cli_manage_command_migrate_spec_bar_tags")
      end
    end

    # Reset local migration app configs to avoid them to be used elsewhere.
    Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226111.reset_app_config
    Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226112.reset_app_config
    Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226113.reset_app_config
    Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226111.reset_app_config
    Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226112.reset_app_config
  end

  before_each do
    Marten::DB::Management::Migrations::Record
      .filter(app__startswith: "cli_manage_command_migrate_spec_")
      .delete(raw: true)

    introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
    Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
      if introspector.table_names.includes?("cli_manage_command_migrate_spec_foo_tags")
        schema_editor.delete_table("cli_manage_command_migrate_spec_foo_tags")
      end

      if introspector.table_names.includes?("cli_manage_command_migrate_spec_bar_tags")
        schema_editor.delete_table("cli_manage_command_migrate_spec_bar_tags")
      end
    end
  end

  describe "#run" do
    it "shows the expected message when no migrations need to be applied" do
      Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default).execute

      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Migrate.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      stdout.rewind.gets_to_end.includes?("No pending migrations to apply").should be_true
    end

    it "applies all the migrations when no migrations are already applied" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Migrate.new(
        options: [] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226113.id).should be_true
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226111.id).should be_true
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226112.id).should be_true

      expected_migrations = [
        Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226111,
        Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226112,
        Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226113,
        Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226111,
        Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226112,
      ]

      expected_migrations.each do |migration|
        Marten::DB::Management::Migrations::Record.filter(
          app: migration.app_config.label,
          name: migration.migration_name
        ).exists?.should be_true
      end

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      introspector.table_names.includes?("cli_manage_command_migrate_spec_foo_tags").should be_true
      columns_details = introspector.columns_details("cli_manage_command_migrate_spec_foo_tags")
      columns_details.map(&.name).sort!.should eq ["active", "id", "label"]

      introspector.table_names.includes?("cli_manage_command_migrate_spec_bar_tags").should be_true
      columns_details = introspector.columns_details("cli_manage_command_migrate_spec_bar_tags")
      columns_details.map(&.name).sort!.should eq ["active", "id", "label"]
    end

    it "is able to apply specific app migrations up to a certain version" do
      bar_app = Marten::CLI::Manage::Command::MigrateSpec::BarApp.new

      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Migrate.new(
        options: [
          "cli_manage_command_migrate_spec_bar_app",
          Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226111.migration_name,
        ],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226113.id).should be_true
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226111.id).should be_true

      Marten::DB::Management::Migrations::Record.filter(
        app: bar_app.label,
        name: Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226111.migration_name
      ).exists?.should be_true

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      introspector.table_names.includes?("cli_manage_command_migrate_spec_bar_tags").should be_true
      columns_details = introspector.columns_details("cli_manage_command_migrate_spec_bar_tags")
      columns_details.map(&.name).sort!.should eq ["id", "label"]
    end

    it "lists all the planned migrations when no migrations are already applied and the --plan option is used" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Migrate.new(
        options: ["--plan"] of String,
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226113.id).should be_true
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226111.id).should be_true
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226112.id).should be_true

      Marten::DB::Management::Migrations::Record
        .filter(app__startswith: "cli_manage_command_migrate_spec_")
        .size
        .should eq 0
    end

    it "is able to apply specific app migrations up to a certain version" do
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      command = Marten::CLI::Manage::Command::Migrate.new(
        options: [
          "cli_manage_command_migrate_spec_bar_app",
          Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226111.migration_name,
          "--plan",
        ],
        stdout: stdout,
        stderr: stderr
      )

      command.handle

      output = stdout.rewind.gets_to_end
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226113.id).should be_true
      output.includes?(Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226111.id).should be_true

      Marten::DB::Management::Migrations::Record
        .filter(app__startswith: "cli_manage_command_migrate_spec_")
        .size
        .should eq 0
    end
  end
end
