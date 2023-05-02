class Marten::CLI::Manage::Command::MigrateSpec::BarApp::V202108092226112 < Marten::Migration
  depends_on "cli_manage_command_migrate_spec_bar_app", "202108092226111_auto"

  def plan
    add_column :cli_manage_command_migrate_spec_bar_tags, :active, :bool, default: true
  end
end
