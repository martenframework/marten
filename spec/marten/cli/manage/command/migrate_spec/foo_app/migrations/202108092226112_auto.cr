class Marten::CLI::Manage::Command::MigrateSpec::FooApp::V202108092226112 < Marten::Migration
  depends_on "cli_manage_command_migrate_spec_foo_app", "202108092226111_auto"

  def plan
    add_column :cli_manage_command_migrate_spec_foo_tags, :active, :bool, default: true
  end
end
