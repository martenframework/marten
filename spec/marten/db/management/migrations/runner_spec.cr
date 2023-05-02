require "./spec_helper"
require "./runner_spec/**"

describe Marten::DB::Management::Migrations::Runner do
  with_installed_apps(
    Marten::DB::Management::Migrations::RunnerSpec::FooApp,
    Marten::DB::Management::Migrations::RunnerSpec::BarApp
  )

  before_all do
    Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.default).setup
    Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.get(:other)).setup
  end

  after_all do
    Marten::DB::Management::Migrations::Record.filter(app__startswith: "runner_spec_").delete(raw: true)

    introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
    Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
      schema_editor.delete_table("runner_spec_foo_tags") if introspector.table_names.includes?("runner_spec_foo_tags")
      schema_editor.delete_table("runner_spec_bar_tags") if introspector.table_names.includes?("runner_spec_bar_tags")
    end

    # Reset local migration app configs to avoid them to be used elsewhere.
    Migration::RunnerSpec::FooApp::V202108092226111.reset_app_config
    Migration::RunnerSpec::FooApp::V202108092226112.reset_app_config
    Migration::RunnerSpec::FooApp::V202108092226113.reset_app_config
    Migration::RunnerSpec::BarApp::V202108092226111.reset_app_config
    Migration::RunnerSpec::BarApp::V202108092226112.reset_app_config
  end

  before_each do
    Marten::DB::Management::Migrations::Record.filter(app__startswith: "runner_spec_").delete(raw: true)

    introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)
    Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
      schema_editor.delete_table("runner_spec_foo_tags") if introspector.table_names.includes?("runner_spec_foo_tags")
      schema_editor.delete_table("runner_spec_bar_tags") if introspector.table_names.includes?("runner_spec_bar_tags")
    end
  end

  describe "#execute" do
    it "applies all the migrations when no migrations are already applied" do
      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execute

      expected_migrations = [
        Migration::RunnerSpec::FooApp::V202108092226111,
        Migration::RunnerSpec::FooApp::V202108092226112,
        Migration::RunnerSpec::FooApp::V202108092226113,
        Migration::RunnerSpec::BarApp::V202108092226111,
        Migration::RunnerSpec::BarApp::V202108092226112,
      ]

      expected_migrations.each do |migration|
        Marten::DB::Management::Migrations::Record.filter(
          app: migration.app_config.label,
          name: migration.migration_name
        ).exists?.should be_true
      end

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      introspector.table_names.includes?("runner_spec_foo_tags").should be_true
      columns_details = introspector.columns_details("runner_spec_foo_tags")
      columns_details.map(&.name).sort!.should eq ["active", "id", "label"]

      introspector.table_names.includes?("runner_spec_bar_tags").should be_true
      columns_details = introspector.columns_details("runner_spec_bar_tags")
      columns_details.map(&.name).sort!.should eq ["active", "id", "label"]
    end

    it "is able to apply specific app migrations up to a certain version" do
      bar_app = Marten::DB::Management::Migrations::RunnerSpec::BarApp.new

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execute(
        app_config: bar_app,
        migration_name: Migration::RunnerSpec::BarApp::V202108092226111.migration_name
      )

      Marten::DB::Management::Migrations::Record.filter(
        app: bar_app.label,
        name: Migration::RunnerSpec::BarApp::V202108092226111.migration_name
      ).exists?.should be_true

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      introspector.table_names.includes?("runner_spec_bar_tags").should be_true
      columns_details = introspector.columns_details("runner_spec_bar_tags")
      columns_details.map(&.name).sort!.should eq ["id", "label"]
    end

    it "is able to fake all the migrations to run forward" do
      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execute(fake: true)

      expected_migrations = [
        Migration::RunnerSpec::FooApp::V202108092226111,
        Migration::RunnerSpec::FooApp::V202108092226112,
        Migration::RunnerSpec::FooApp::V202108092226113,
        Migration::RunnerSpec::BarApp::V202108092226111,
        Migration::RunnerSpec::BarApp::V202108092226112,
      ]

      expected_migrations.each do |migration|
        Marten::DB::Management::Migrations::Record.filter(
          app: migration.app_config.label,
          name: migration.migration_name
        ).exists?.should be_true
      end

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      introspector.table_names.includes?("runner_spec_foo_tags").should be_false
      introspector.table_names.includes?("runner_spec_bar_tags").should be_false
    end

    it "is able to fake a specific migration forward" do
      bar_app = Marten::DB::Management::Migrations::RunnerSpec::BarApp.new

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execute(
        app_config: bar_app,
        migration_name: Migration::RunnerSpec::BarApp::V202108092226111.migration_name,
        fake: true
      )

      Marten::DB::Management::Migrations::Record.filter(
        app: bar_app.label,
        name: Migration::RunnerSpec::BarApp::V202108092226111.migration_name
      ).exists?.should be_true

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      introspector.table_names.includes?("runner_spec_bar_tags").should be_false
    end

    it "marks replacement migrations as applied if the replaced migrations were applied during the runner execution" do
      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execute

      Marten::DB::Management::Migrations::Record.filter(
        app: Marten::DB::Management::Migrations::RunnerSpec::FooApp.label,
        name: Migration::RunnerSpec::FooApp::V202108092226113.migration_name
      ).exists?.should be_true

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      introspector.table_names.includes?("runner_spec_foo_tags").should be_true
    end

    it "marks replacement migrations as applied if the replaced migrations were applied before the runner execution" do
      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::RunnerSpec::FooApp.label,
        name: Migration::RunnerSpec::FooApp::V202108092226111.migration_name
      )
      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::RunnerSpec::FooApp.label,
        name: Migration::RunnerSpec::FooApp::V202108092226112.migration_name
      )

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execute

      Marten::DB::Management::Migrations::Record.filter(
        app: Marten::DB::Management::Migrations::RunnerSpec::FooApp.label,
        name: Migration::RunnerSpec::FooApp::V202108092226113.migration_name
      ).exists?.should be_true
    end

    it "is able to unapply all the migrations of a specific app" do
      Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default).execute

      bar_app = Marten::DB::Management::Migrations::RunnerSpec::BarApp.new

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execute(app_config: bar_app, migration_name: "zero")

      expected_migrations = [
        Migration::RunnerSpec::BarApp::V202108092226111,
        Migration::RunnerSpec::BarApp::V202108092226112,
      ]

      expected_migrations.each do |migration|
        Marten::DB::Management::Migrations::Record.filter(
          app: migration.app_config.label,
          name: migration.migration_name
        ).exists?.should be_false
      end

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      introspector.table_names.includes?("runner_spec_bar_tags").should be_false
    end

    it "is able to unapply the migrations of a specific app up to a specific version" do
      Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default).execute

      bar_app = Marten::DB::Management::Migrations::RunnerSpec::BarApp.new

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execute(
        app_config: bar_app,
        migration_name: Migration::RunnerSpec::BarApp::V202108092226111.migration_name
      )

      Marten::DB::Management::Migrations::Record.filter(
        app: bar_app.label,
        name: Migration::RunnerSpec::BarApp::V202108092226112.migration_name
      ).exists?.should be_false

      introspector = Marten::DB::Management::Introspector.for(Marten::DB::Connection.default)

      introspector.table_names.includes?("runner_spec_bar_tags").should be_true
      columns_details = introspector.columns_details("runner_spec_bar_tags")
      columns_details.map(&.name).sort!.should eq ["id", "label"]
    end
  end

  describe "#execution_needed?" do
    it "returns true if migrations are not applied" do
      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execution_needed?.should be_true
    end

    it "returns true if only some of migrations are applied" do
      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::RunnerSpec::FooApp.label,
        name: Migration::RunnerSpec::FooApp::V202108092226111.migration_name
      )

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execution_needed?.should be_true
    end

    it "returns true if all the migrations of a specific app are not applied" do
      foo_app = Marten::DB::Management::Migrations::RunnerSpec::FooApp.new

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execution_needed?(app_config: foo_app).should be_true
    end

    it "returns true if only some of the migrations of a specific app are applied" do
      foo_app = Marten::DB::Management::Migrations::RunnerSpec::FooApp.new

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::RunnerSpec::FooApp.label,
        name: Migration::RunnerSpec::FooApp::V202108092226111.migration_name
      )

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execution_needed?(app_config: foo_app).should be_true
    end

    it "returns true if migrations up to a specific migration version are not already applied" do
      foo_app = Marten::DB::Management::Migrations::RunnerSpec::FooApp.new

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::RunnerSpec::FooApp.label,
        name: Migration::RunnerSpec::FooApp::V202108092226111.migration_name
      )

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execution_needed?(
        app_config: foo_app,
        migration_name: Migration::RunnerSpec::FooApp::V202108092226112.migration_name
      ).should be_true
    end

    it "returns false if migrations are already applied" do
      Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default).execute

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execution_needed?.should be_false
    end

    it "returns false if all the migrations of a specific app are already applied" do
      foo_app = Marten::DB::Management::Migrations::RunnerSpec::FooApp.new

      Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default).execute

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execution_needed?(app_config: foo_app).should be_false
    end

    it "returns false if migrations up to a specific migration version are already applied" do
      foo_app = Marten::DB::Management::Migrations::RunnerSpec::FooApp.new

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::RunnerSpec::FooApp.label,
        name: Migration::RunnerSpec::FooApp::V202108092226111.migration_name
      )

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      runner.execution_needed?(
        app_config: foo_app,
        migration_name: Migration::RunnerSpec::FooApp::V202108092226111.migration_name
      ).should be_false
    end
  end

  describe "#plan" do
    it "returns the expected migrations when no migrations are already applied" do
      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      plan = runner.plan

      plan.size.should eq 3

      [
        Migration::RunnerSpec::FooApp::V202108092226113,
        Migration::RunnerSpec::BarApp::V202108092226111,
        Migration::RunnerSpec::BarApp::V202108092226112,
      ].each_with_index do |migration_klass, index|
        plan[index][0].class.should eq migration_klass
        plan[index][1].should be_false
      end
    end

    it "returns the expected migrations when applying specific app migrations up to a certain version" do
      bar_app = Marten::DB::Management::Migrations::RunnerSpec::BarApp.new

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      plan = runner.plan(
        app_config: bar_app,
        migration_name: Migration::RunnerSpec::BarApp::V202108092226111.migration_name
      )

      plan.size.should eq 2

      [
        Migration::RunnerSpec::FooApp::V202108092226113,
        Migration::RunnerSpec::BarApp::V202108092226111,
      ].each_with_index do |migration_klass, index|
        plan[index][0].class.should eq migration_klass
        plan[index][1].should be_false
      end
    end

    it "returns the expected migrations when unapplying all the migrations of a specific app" do
      Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default).execute

      bar_app = Marten::DB::Management::Migrations::RunnerSpec::BarApp.new

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      plan = runner.plan(app_config: bar_app, migration_name: "zero")

      plan.size.should eq 2

      [
        Migration::RunnerSpec::BarApp::V202108092226112,
        Migration::RunnerSpec::BarApp::V202108092226111,
      ].each_with_index do |migration_klass, index|
        plan[index][0].class.should eq migration_klass
        plan[index][1].should be_true # backward
      end
    end

    it "returns the expected migrations when unapplying the migrations of a specific app up to a specific version" do
      Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default).execute

      bar_app = Marten::DB::Management::Migrations::RunnerSpec::BarApp.new

      runner = Marten::DB::Management::Migrations::Runner.new(Marten::DB::Connection.default)
      plan = runner.plan(
        app_config: bar_app,
        migration_name: Migration::RunnerSpec::BarApp::V202108092226111.migration_name
      )

      plan.size.should eq 1
      plan[0][0].class.should eq Migration::RunnerSpec::BarApp::V202108092226112
      plan[0][1].should be_true # backward
    end
  end
end
