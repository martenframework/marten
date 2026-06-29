class Migration::RunnerSpec::FooApp::V209901010101101 < Marten::Migration
  replaces "runner_spec_foo_app", "ghost_migration"

  def forward(schema_editor)
  end

  def backward(schema_editor)
  end
end
