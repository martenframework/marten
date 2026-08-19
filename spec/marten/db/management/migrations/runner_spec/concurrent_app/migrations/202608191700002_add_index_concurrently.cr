class Migration::RunnerSpec::ConcurrentApp::V202608191700002 < Marten::Migration
  depends_on "runner_spec_concurrent_app", "202608191700001_create_table"

  def plan
    add_index :runner_spec_concurrent_tags, :index_runner_spec_concurrent_tags_label, [:label], concurrently: true
  end
end
