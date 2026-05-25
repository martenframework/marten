class Marten::CLI::Manage::Command::GenMigrationsSpec::SyncedApp::V202108092226112 < Marten::Migration
  depends_on "cli_manage_command_gen_migrations_spec_synced_app", "202108092226111_auto"

  def plan
    add_column :cli_manage_command_gen_migrations_spec_synced_app_tags, :active, :bool, default: true
  end
end
