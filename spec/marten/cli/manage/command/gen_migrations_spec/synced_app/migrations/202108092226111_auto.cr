class Marten::CLI::Manage::Command::GenMigrationsSpec::SyncedApp::V202108092226111 < Marten::Migration
  def plan
    create_table :cli_manage_command_gen_migrations_spec_synced_app_tag do
      column :id, :big_int, primary_key: true, auto: true
      column :label, :string, max_size: 255, unique: true
    end
  end
end
