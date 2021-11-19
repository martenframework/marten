class Migration::FooApp::V202108092226112 < Marten::Migration
  depends_on "reader_spec_foo_app", "202108092226111_auto"

  def plan
    add_column :foo_tags, :active, :bool, default: true
  end
end
