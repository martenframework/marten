class Migration::RunnerSpec::BarApp::V202108092226112 < Marten::Migration
  depends_on "runner_spec_bar_app", "202108092226111_auto"

  def plan
    add_column :runner_spec_bar_tags, :active, :bool, default: true
  end
end
