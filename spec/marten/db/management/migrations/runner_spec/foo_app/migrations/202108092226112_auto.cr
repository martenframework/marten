class Migration::RunnerSpec::FooApp::V202108092226112 < Marten::Migration
  depends_on "runner_spec_foo_app", "202108092226111_auto"

  def plan
    add_column :runner_spec_foo_tags, :active, :bool, default: true
  end
end
