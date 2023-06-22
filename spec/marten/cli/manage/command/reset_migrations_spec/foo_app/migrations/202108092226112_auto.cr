class Migration::ResetMigrationsSpec::FooApp::V202108092226112 < Marten::Migration
  depends_on "reset_migrations_spec_foo_app", "202108092226111_auto"

  def plan
    add_column :reset_migrations_spec_foo_app_tags, :active, :bool, default: true
  end
end
