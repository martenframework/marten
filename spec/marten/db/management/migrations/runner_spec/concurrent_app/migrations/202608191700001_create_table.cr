class Migration::RunnerSpec::ConcurrentApp::V202608191700001 < Marten::Migration
  def plan
    create_table :runner_spec_concurrent_tags do
      column :id, :big_int, primary_key: true, auto: true
      column :label, :string, max_size: 255
    end
  end
end
