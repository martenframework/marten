class Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112 < Marten::Migration
  depends_on "reader_spec_foo_app", "202108092226111_auto"

  def plan
    add_column :reader_spec_foo_app_tags, :active, :bool, default: true
  end
end
