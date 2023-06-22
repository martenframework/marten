class Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111 < Marten::Migration
  def plan
    create_table :reader_spec_foo_app_tags do
      column :id, :big_int, primary_key: true, auto: true
      column :label, :string, max_size: 255, unique: true
    end
  end
end
