require "./spec_helper"
require "./reader_spec/**"

describe Marten::DB::Management::Migrations::Reader do
  before_all do
    Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.default).setup
    Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.get(:other)).setup
  end

  before_each do
    Marten::DB::Management::Migrations::Record.filter(app__startswith: "reader_spec_").delete(raw: true)
  end

  around_each do |t|
    original_app_configs_store = Marten.apps.app_configs_store

    t.run

    Marten.apps.app_configs_store = original_app_configs_store
  end

  describe "::new" do
    it "identifies already applied migrations" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.applied_migrations.size.should eq 1
      reader.applied_migrations[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111
      )
    end

    it "identifies already applied migrations that are no longer defined" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )
      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: "very_old_migration"
      )

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.applied_migrations.size.should eq 2
      reader.applied_migrations[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111
      )

      old_migration_id = [
        Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        "very_old_migration",
      ].join("_")
      reader.applied_migrations[old_migration_id].should be_nil
    end

    it "identifies already applied migrations by respecting the considered DB connection" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.using(:other).create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )

      reader_1 = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.get(:other))
      reader_2 = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader_1.applied_migrations.size.should eq 1
      reader_1.applied_migrations[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111
      )

      reader_2.applied_migrations.should be_empty
    end

    it "identifies a recorded replacement migration as applied if all the replaced migrations were already applied" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )
      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112.migration_name
      )
      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113.migration_name
      )

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.applied_migrations.size.should eq 3
      reader.applied_migrations[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111
      )
      reader.applied_migrations[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112
      )
      reader.applied_migrations[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113
      )
    end

    it "does not identify a replacement migration if it is not recorded and the replaced migrations are applied" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )
      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112.migration_name
      )

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.applied_migrations.size.should eq 2
      reader.applied_migrations[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111
      )
      reader.applied_migrations[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112
      )
    end

    it "does not identify a replacement migration as applied if not all the replaced migrations were applied" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.applied_migrations.size.should eq 1
      reader.applied_migrations[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111
      )
    end

    it "adds a node for each defined migration" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      node = reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::BarApp::V202108092226111.id)
      node.migration.should be_a Marten::DB::Management::Migrations::ReaderSpec::BarApp::V202108092226111
    end

    it "adds the replacement migration to the graph if no replaced migration was applied" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      expect_raises(Marten::DB::Management::Migrations::Errors::UnknownNode) do
        reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id)
      end

      expect_raises(Marten::DB::Management::Migrations::Errors::UnknownNode) do
        reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112.id)
      end

      node = reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113.id)
      node.migration.should be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113
    end

    it "adds the replacement migration to the graph if all the replaced migrations were applied" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )
      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112.migration_name
      )

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      expect_raises(Marten::DB::Management::Migrations::Errors::UnknownNode) do
        reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id)
      end

      expect_raises(Marten::DB::Management::Migrations::Errors::UnknownNode) do
        reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112.id)
      end

      node = reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113.id)
      node.migration.should be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113
    end

    it "does not add the replacement migration to the graph if only some replaced replaced migrations were applied" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      node_1 = reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id)
      node_1.migration.should be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111

      node_2 = reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112.id)
      node_2.migration.should be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112

      expect_raises(Marten::DB::Management::Migrations::Errors::UnknownNode) do
        reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113.id)
      end
    end

    it "properly configures in-app dependencies in the graph" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      node_1 = reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id)
      node_1.migration.should be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111

      node_2 = reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112.id)
      node_2.migration.should be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226112

      node_1.parents.should be_empty
      node_1.children.includes?(node_2).should be_true

      node_2.parents.includes?(node_1).should be_true
      node_2.children.should be_empty
    end

    it "properly configures cross-app dependencies in the graph" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      Marten::DB::Management::Migrations::Record.create!(
        app: Marten::DB::Management::Migrations::ReaderSpec::FooApp.label,
        name: Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.migration_name
      )

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      node_1 = reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111.id)
      node_1.migration.should be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111

      node_2 = reader.graph.find_node(Marten::DB::Management::Migrations::ReaderSpec::BarApp::V202108092226111.id)
      node_2.migration.should be_a Marten::DB::Management::Migrations::ReaderSpec::BarApp::V202108092226111

      node_1.parents.should be_empty
      node_1.children.includes?(node_2).should be_true

      node_2.parents.includes?(node_1).should be_true
      node_2.children.should be_empty
    end

    it "assigns an empty set of replacements when apps do not have replacement migrations" do
      Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113.reset_app_config

      Marten.apps.app_configs_store = {
        "reader_spec_bar_app"                => Marten::DB::Management::Migrations::ReaderSpec::BarApp.new,
        "reader_spec_app_without_migrations" => (
          Marten::DB::Management::Migrations::ReaderSpec::AppWithoutMigrations.new
        ),
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.replacements.should be_empty
    end

    it "assigns the right replacement migrations when apps have replacement migrations" do
      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => Marten::DB::Management::Migrations::ReaderSpec::FooApp.new,
        "reader_spec_bar_app" => Marten::DB::Management::Migrations::ReaderSpec::BarApp.new,
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.replacements.size.should eq 1
      reader.replacements[Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113.id].should(
        be_a Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113
      )
    end
  end

  describe "#apps_with_migrations" do
    it "returns an array of all the app configs with migrations" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app"                => foo_app,
        "reader_spec_bar_app"                => bar_app,
        "reader_spec_app_without_migrations" => (
          Marten::DB::Management::Migrations::ReaderSpec::AppWithoutMigrations.new
        ),
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)
      reader.apps_with_migrations.to_set.should eq [foo_app, bar_app].to_set
    end
  end

  describe "#get_migration" do
    it "returns the migration class corresponding to a full migration name" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app"                => foo_app,
        "reader_spec_bar_app"                => bar_app,
        "reader_spec_app_without_migrations" => (
          Marten::DB::Management::Migrations::ReaderSpec::AppWithoutMigrations.new
        ),
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.get_migration(foo_app, "202108092226111_auto").should(
        eq Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111
      )
      reader.get_migration(bar_app, "202108092226111_auto").should(
        eq Marten::DB::Management::Migrations::ReaderSpec::BarApp::V202108092226111
      )
    end

    it "returns the migration class corresponding to a partial migration name" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app"                => foo_app,
        "reader_spec_bar_app"                => bar_app,
        "reader_spec_app_without_migrations" => (
          Marten::DB::Management::Migrations::ReaderSpec::AppWithoutMigrations.new
        ),
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.get_migration(foo_app, "202108092226111").should(
        eq Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226111
      )
      reader.get_migration(bar_app, "202108092226111").should(
        eq Marten::DB::Management::Migrations::ReaderSpec::BarApp::V202108092226111
      )
    end

    it "raises the expected error if the migration name does not exists within the app" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app"                => foo_app,
        "reader_spec_app_without_migrations" => (
          Marten::DB::Management::Migrations::ReaderSpec::AppWithoutMigrations.new
        ),
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      expect_raises(
        Marten::DB::Management::Migrations::Errors::MigrationNotFound,
        "No migration 'unknown' associated with app 'reader_spec_foo_app'"
      ) do
        reader.get_migration(foo_app, "unknown")
      end
    end

    it "raises the expected error if the passed app object is not part of the apps registry" do
      other_app = Marten::DB::Management::Migrations::ReaderSpec::OtherApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_bar_app"                => bar_app,
        "reader_spec_app_without_migrations" => (
          Marten::DB::Management::Migrations::ReaderSpec::AppWithoutMigrations.new
        ),
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      expect_raises(
        Marten::DB::Management::Migrations::Errors::MigrationNotFound,
        "No migration '202108092226111_auto' associated with app 'reader_spec_other_app'"
      ) do
        reader.get_migration(other_app, "202108092226111_auto")
      end
    end
  end

  describe "#latest_migration" do
    it "returns the latest migration for a given app config" do
      foo_app = Marten::DB::Management::Migrations::ReaderSpec::FooApp.new
      bar_app = Marten::DB::Management::Migrations::ReaderSpec::BarApp.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => foo_app,
        "reader_spec_bar_app" => bar_app,
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.latest_migration(foo_app).should(
        eq Marten::DB::Management::Migrations::ReaderSpec::FooApp::V202108092226113
      )
      reader.latest_migration(bar_app).should(
        eq Marten::DB::Management::Migrations::ReaderSpec::BarApp::V202108092226111
      )
    end

    it "returns nil if the app config does not have any migrations" do
      app = Marten::DB::Management::Migrations::ReaderSpec::AppWithoutMigrations.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app"                => Marten::DB::Management::Migrations::ReaderSpec::FooApp.new,
        "reader_spec_app_without_migrations" => app,
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.latest_migration(app).should be_nil
    end

    it "returns nil if the app config does not exist in the apps registry" do
      app = Marten::DB::Management::Migrations::ReaderSpec::AppWithoutMigrations.new

      Marten.apps.app_configs_store = {
        "reader_spec_foo_app" => Marten::DB::Management::Migrations::ReaderSpec::FooApp.new,
        "reader_spec_bar_app" => Marten::DB::Management::Migrations::ReaderSpec::BarApp.new,
      }

      reader = Marten::DB::Management::Migrations::Reader.new(Marten::DB::Connection.default)

      reader.latest_migration(app).should be_nil
    end
  end
end
