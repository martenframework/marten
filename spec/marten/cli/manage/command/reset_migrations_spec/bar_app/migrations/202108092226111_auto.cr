class Migration::ResetMigrationsSpec::BarApp::V202108092226111 < Marten::Migration
  depends_on "reset_migrations_spec_foo_app", "202108092226111_auto"

  def plan
    create_table :reset_migrations_spec_bar_app_tags do
      column :id, :big_int, primary_key: true, auto: true
      column :label, :string, max_size: 255, unique: true
    end
  end
end
