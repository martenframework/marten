class Migration::ResetMigrationsSpec::FooApp::V202108092226111 < Marten::Migration
  def plan
    create_table :reset_migrations_spec_foo_app_tags do
      column :id, :big_int, primary_key: true, auto: true
      column :label, :string, max_size: 255, unique: true
    end
  end
end
