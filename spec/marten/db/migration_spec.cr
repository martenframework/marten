require "./spec_helper"

describe Marten::DB::Migration do
  describe "::atomic" do
    it "returns true by default" do
      Marten::DB::MigrationSpec::EmptyMigration.atomic.should be_true
    end

    it "returns true if migration atomicity is explicitly enabled" do
      Marten::DB::MigrationSpec::AtomicMigration.atomic.should be_true
    end

    it "returns false if migration atomicity is disabled" do
      Marten::DB::MigrationSpec::NonAtomicMigration.atomic.should be_false
    end
  end

  describe "::atomic(atomicity)" do
    it "allows to enable migration atomicity" do
      Marten::DB::MigrationSpec::AtomicMigration.atomic.should be_true
    end

    it "allows to disable migration atomicity" do
      Marten::DB::MigrationSpec::NonAtomicMigration.atomic.should be_false
    end
  end

  describe "::depends_on" do
    it "returns an empty array by default" do
      Marten::DB::MigrationSpec::EmptyMigration.depends_on.should be_empty
    end

    it "returns an array of the migration dependencies" do
      Marten::DB::MigrationSpec::MigrationWithDependencies.depends_on.size.should eq 2
      Marten::DB::MigrationSpec::MigrationWithDependencies.depends_on[0].should eq({"my_app", "my_migration_id"})
      Marten::DB::MigrationSpec::MigrationWithDependencies.depends_on[1].should eq(
        {"my_other_app", "my_other_migration_id"}
      )
    end
  end

  describe "::id" do
    it "returns a migration ID based on the app label and the file name" do
      Marten::DB::MigrationSpec::EmptyMigration.id.should eq "app_migration_spec"
    end
  end

  describe "::replaces" do
    it "returns an empty array by default" do
      Marten::DB::MigrationSpec::EmptyMigration.replaces.should be_empty
    end

    it "returns an array of replacements" do
      Marten::DB::MigrationSpec::MigrationWithReplacements.replaces.size.should eq 1
      Marten::DB::MigrationSpec::MigrationWithReplacements.replaces[0].should eq({"my_app", "old_migration_id"})
    end
  end

  describe "::replacement_ids" do
    it "returns an empty array by default" do
      Marten::DB::MigrationSpec::EmptyMigration.replacement_ids.should be_empty
    end

    it "returns an array of replacement IDs" do
      Marten::DB::MigrationSpec::MigrationWithReplacements.replacement_ids.size.should eq 1
      Marten::DB::MigrationSpec::MigrationWithReplacements.replacement_ids[0].should eq "my_app_old_migration_id"
    end
  end

  describe "#apply_backward" do
    before_each do
      introspector = Marten::DB::Connection.default.introspector

      Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
        schema_editor.execute(
          schema_editor.delete_table_statement("migration_test_table1")
        ) if introspector.table_names.includes?("migration_test_table1")
        schema_editor.execute(
          schema_editor.delete_table_statement("migration_test_table2")
        ) if introspector.table_names.includes?("migration_test_table2")
      end
    end

    it "unapplies the expected biderectional operations when applicable" do
      table_state_1 = Marten::DB::Management::TableState.new(
        "app",
        "migration_test_table1",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::String.new("label", max_size: 255),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      table_state_2 = Marten::DB::Management::TableState.new(
        "app",
        "migration_test_table2",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::String.new("name", max_size: 255),
          Marten::DB::Management::Column::ForeignKey.new("other_id", "migration_test_table1", "id"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      project_state = Marten::DB::Management::ProjectState.new([table_state_1, table_state_2])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(table_state_1)
      schema_editor.create_table(table_state_2)

      migration = Marten::DB::MigrationSpec::MigrationToCreateTwoNewTables.new
      resulting_project_state = migration.apply_backward(
        pre_forward_project_state: Marten::DB::Management::ProjectState.new,
        project_state: project_state,
        schema_editor: schema_editor
      )

      resulting_project_state.tables.should be_empty

      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table1").should be_false
      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table2").should be_false
    end

    it "unapplies the expected directed operations when applicable" do
      table_state_1 = Marten::DB::Management::TableState.new(
        "app",
        "migration_test_table1",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::String.new("label", max_size: 255),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      table_state_2 = Marten::DB::Management::TableState.new(
        "app",
        "migration_test_table2",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::String.new("name", max_size: 255),
          Marten::DB::Management::Column::ForeignKey.new("other_id", "migration_test_table1", "id"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      project_state = Marten::DB::Management::ProjectState.new([table_state_1, table_state_2])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(table_state_1)
      schema_editor.create_table(table_state_2)

      migration = Marten::DB::MigrationSpec::MigrationToCreateTwoNewTablesWithExplicitDirectedOperations.new
      resulting_project_state = migration.apply_backward(
        pre_forward_project_state: Marten::DB::Management::ProjectState.new,
        project_state: project_state,
        schema_editor: schema_editor
      )

      resulting_project_state.tables.should be_empty

      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table1").should be_false
      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table2").should be_false
    end

    it "unapplies the expected operations in sequence" do
      table_state = Marten::DB::Management::TableState.new(
        "app",
        "migration_test_table1",
        columns: [
          Marten::DB::Management::Column::BigAuto.new("id", primary_key: true),
          Marten::DB::Management::Column::String.new("label", max_size: 255),
          Marten::DB::Management::Column::Bool.new("published", default: false),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )

      project_state = Marten::DB::Management::ProjectState.new([table_state])

      schema_editor = Marten::DB::Connection.default.schema_editor
      schema_editor.create_table(table_state)

      migration = Marten::DB::MigrationSpec::MigrationToCreateOneTableAndToAddAColumn.new
      resulting_project_state = migration.apply_backward(
        pre_forward_project_state: Marten::DB::Management::ProjectState.new,
        project_state: project_state,
        schema_editor: schema_editor
      )

      resulting_project_state.tables.should be_empty

      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table1").should be_false
    end
  end

  describe "#apply_forward" do
    before_each do
      introspector = Marten::DB::Connection.default.introspector

      Marten::DB::Management::SchemaEditor.run_for(Marten::DB::Connection.default) do |schema_editor|
        schema_editor.execute(
          schema_editor.delete_table_statement("migration_test_table1")
        ) if introspector.table_names.includes?("migration_test_table1")
        schema_editor.execute(
          schema_editor.delete_table_statement("migration_test_table2")
        ) if introspector.table_names.includes?("migration_test_table2")
      end
    end

    it "applies the expected biderectional operations when applicable" do
      project_state = Marten::DB::Management::ProjectState.new
      schema_editor = Marten::DB::Connection.default.schema_editor

      migration = Marten::DB::MigrationSpec::MigrationToCreateTwoNewTables.new
      resulting_project_state = migration.apply_forward(project_state, schema_editor)

      resulting_project_state.tables.size.should eq 2
      resulting_project_state.tables.values[0].name.should eq "migration_test_table1"
      resulting_project_state.tables.values[1].name.should eq "migration_test_table2"

      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table1").should be_true
      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table2").should be_true
    end

    it "applies the expected directed operations when applicable" do
      project_state = Marten::DB::Management::ProjectState.new
      schema_editor = Marten::DB::Connection.default.schema_editor

      migration = Marten::DB::MigrationSpec::MigrationToCreateTwoNewTablesWithExplicitDirectedOperations.new
      resulting_project_state = migration.apply_forward(project_state, schema_editor)

      resulting_project_state.tables.size.should eq 2
      resulting_project_state.tables.values[0].name.should eq "migration_test_table1"
      resulting_project_state.tables.values[1].name.should eq "migration_test_table2"

      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table1").should be_true
      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table2").should be_true
    end

    it "applies the expected operations in sequence" do
      project_state = Marten::DB::Management::ProjectState.new
      schema_editor = Marten::DB::Connection.default.schema_editor

      migration = Marten::DB::MigrationSpec::MigrationToCreateOneTableAndToAddAColumn.new
      resulting_project_state = migration.apply_forward(project_state, schema_editor)

      resulting_project_state.tables.size.should eq 1
      resulting_project_state.tables.values[0].name.should eq "migration_test_table1"
      resulting_project_state.tables.values[0].columns.size.should eq 3
      resulting_project_state.tables.values[0].columns[0].name = "id"
      resulting_project_state.tables.values[0].columns[1].name = "label"
      resulting_project_state.tables.values[0].columns[2].name = "published"

      Marten::DB::Connection.default.introspector.table_names.includes?("migration_test_table1").should be_true

      column_names = [] of String

      Marten::DB::Connection.default.open do |db|
        {% if env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
          db.query("SHOW COLUMNS FROM migration_test_table1") do |rs|
            rs.each do
              column_names << rs.read(String)
            end
          end
        {% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
          db.query(
            <<-SQL
              SELECT column_name, data_type, is_nullable, column_default
              FROM information_schema.columns
              WHERE table_name = 'migration_test_table1'
            SQL
          ) do |rs|
            rs.each do
              column_names << rs.read(String)
            end
          end
        {% else %}
          db.query("PRAGMA table_info(migration_test_table1)") do |rs|
            rs.each do
              rs.read(Int32 | Int64)
              column_names << rs.read(String)
            end
          end
        {% end %}
      end

      column_names.to_set.should eq ["id", "label", "published"].to_set
    end
  end

  describe "#id" do
    it "returns a migration ID based on the app label and the file name" do
      Marten::DB::MigrationSpec::EmptyMigration.new.id.should eq "app_migration_spec"
    end
  end

  describe "#mutate_state_forward" do
    it "mutates a project state by applying each of the migration operations" do
      project_state = Marten::DB::Management::ProjectState.new

      migration = Marten::DB::MigrationSpec::MigrationToCreateTwoNewTables.new
      resulting_project_state = migration.mutate_state_forward(project_state)

      resulting_project_state.tables.size.should eq 2
      resulting_project_state.tables.values[0].name.should eq "migration_test_table1"
      resulting_project_state.tables.values[1].name.should eq "migration_test_table2"
    end

    it "preserves the passed project state by default" do
      project_state = Marten::DB::Management::ProjectState.new

      migration = Marten::DB::MigrationSpec::MigrationToCreateTwoNewTables.new
      resulting_project_state = migration.mutate_state_forward(project_state)

      resulting_project_state.should_not be project_state
      project_state.tables.should be_empty
    end

    it "does not preserve the passed project state if the preserve argument is set to false" do
      project_state = Marten::DB::Management::ProjectState.new

      migration = Marten::DB::MigrationSpec::MigrationToCreateTwoNewTables.new
      resulting_project_state = migration.mutate_state_forward(project_state, preserve: false)

      resulting_project_state.should be project_state
      project_state.tables.size.should eq 2
    end
  end
end

module Marten::DB::MigrationSpec
  class EmptyMigration < Marten::DB::Migration
    def self.app_config
      TestApp.new
    end
  end

  class AtomicMigration < Marten::DB::Migration
    atomic true

    def self.app_config
      TestApp.new
    end
  end

  class NonAtomicMigration < Marten::DB::Migration
    atomic false

    def self.app_config
      TestApp.new
    end
  end

  class MigrationWithDependencies < Marten::DB::Migration
    depends_on "my_app", "my_migration_id"
    depends_on "my_other_app", "my_other_migration_id"

    def self.app_config
      TestApp.new
    end
  end

  class MigrationWithReplacements < Marten::DB::Migration
    replaces "my_app", "old_migration_id"

    def self.app_config
      TestApp.new
    end
  end

  class MigrationToCreateTwoNewTables < Marten::DB::Migration
    def plan
      create_table :migration_test_table1 do
        column :id, :big_auto, primary_key: true
        column :label, :string, max_size: 255
      end

      create_table :migration_test_table2 do
        column :id, :big_auto, primary_key: true
        column :name, :string, max_size: 255
        column :other_id, :foreign_key, to_table: :migration_test_table1, to_column: :id
      end
    end

    def self.app_config
      TestApp.new
    end
  end

  class MigrationToCreateOneTableAndToAddAColumn < Marten::DB::Migration
    def plan
      create_table :migration_test_table1 do
        column :id, :big_auto, primary_key: true
        column :label, :string, max_size: 255
      end

      add_column :migration_test_table1, :published, :bool, default: false
    end

    def self.app_config
      TestApp.new
    end
  end

  class MigrationToCreateTwoNewTablesWithExplicitDirectedOperations < Marten::DB::Migration
    def apply
      create_table :migration_test_table1 do
        column :id, :big_auto, primary_key: true
        column :label, :string, max_size: 255
      end

      create_table :migration_test_table2 do
        column :id, :big_auto, primary_key: true
        column :name, :string, max_size: 255
        column :other_id, :foreign_key, to_table: :migration_test_table1, to_column: :id
      end
    end

    def unapply
      delete_table :migration_test_table2
      delete_table :migration_test_table1
    end

    def self.app_config
      TestApp.new
    end
  end

  Marten::DB::Management::Migrations.registry.delete(EmptyMigration)
  Marten::DB::Management::Migrations.registry.delete(AtomicMigration)
  Marten::DB::Management::Migrations.registry.delete(NonAtomicMigration)
  Marten::DB::Management::Migrations.registry.delete(MigrationWithDependencies)
  Marten::DB::Management::Migrations.registry.delete(MigrationWithReplacements)
  Marten::DB::Management::Migrations.registry.delete(MigrationToCreateTwoNewTables)
  Marten::DB::Management::Migrations.registry.delete(MigrationToCreateOneTableAndToAddAColumn)
  Marten::DB::Management::Migrations.registry.delete(MigrationToCreateTwoNewTablesWithExplicitDirectedOperations)
end
