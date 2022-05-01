class Migration::RunnerSpec::FooApp::V202108092226111 < Marten::Migration
  def plan
    create_table :runner_spec_foo_tags do
      column :id, :big_int, primary_key: true, auto: true
      column :label, :string, max_size: 255, unique: true
    end
  end
end
