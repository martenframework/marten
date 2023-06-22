class Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113 < Marten::Migration
  replaces "reader_spec_foo_app", "202108092226111_auto"
  replaces "reader_spec_foo_app", "202108092226112_auto"

  def plan
    create_table :reader_spec_foo_app_tags do
      column :id, :big_int, primary_key: true, auto: true
      column :label, :string, max_size: 255, unique: true
      column :active, :bool, default: true
    end
  end
end
