require "./spec_helper"

describe Marten::DB::Management::Migrations::Diff::Migration do
  describe "#app_label" do
    it "returns the app label associated with the generated migration" do
      migration = Marten::DB::Management::Migrations::Diff::Migration.new(
        app_label: "my_app",
        name: "202107031819361",
        operations: [
          Marten::DB::Migration::Operation::CreateTable.new(
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::Int.new("foo"),
              Marten::DB::Management::Column::Int.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ] of Marten::DB::Migration::Operation::Base,
        dependencies: [{"other_app", "other_migration"}]
      )
      migration.app_label.should eq "my_app"
    end
  end

  describe "#dependencies" do
    it "returns the dependencies associated with the generated migration" do
      migration = Marten::DB::Management::Migrations::Diff::Migration.new(
        app_label: "my_app",
        name: "202107031819361",
        operations: [
          Marten::DB::Migration::Operation::CreateTable.new(
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::Int.new("foo"),
              Marten::DB::Management::Column::Int.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ] of Marten::DB::Migration::Operation::Base,
        dependencies: [{"other_app", "other_migration"}]
      )
      migration.dependencies.should eq [{"other_app", "other_migration"}]
    end
  end

  describe "#name" do
    it "returns the name of the generated migration based on a single operation name if applicable" do
      migration = Marten::DB::Management::Migrations::Diff::Migration.new(
        app_label: "my_app",
        name: "202107031819361",
        operations: [
          Marten::DB::Migration::Operation::CreateTable.new(
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::Int.new("foo"),
              Marten::DB::Management::Column::Int.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ] of Marten::DB::Migration::Operation::Base,
        dependencies: [{"other_app", "other_migration"}]
      )
      migration.name.should eq "202107031819361_create_test_table_table"
    end

    it "returns au automatic name if the generated migration contains more than one operation" do
      migration = Marten::DB::Management::Migrations::Diff::Migration.new(
        app_label: "my_app",
        name: "202107031819361",
        operations: [
          Marten::DB::Migration::Operation::CreateTable.new(
            name: "test_table_1",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
          Marten::DB::Migration::Operation::CreateTable.new(
            name: "test_table_2",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [] of Marten::DB::Management::Constraint::Unique
          ),
        ] of Marten::DB::Migration::Operation::Base,
        dependencies: [{"other_app", "other_migration"}]
      )
      migration.name.should eq "202107031819361_auto"
    end

    it "returns au automatic name if the single operation name size is greater than the allowed limit" do
      migration = Marten::DB::Management::Migrations::Diff::Migration.new(
        app_label: "my_app",
        name: "202107031819361",
        operations: [
          Marten::DB::Migration::Operation::CreateTable.new(
            name: "x" * 255,
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::Int.new("foo"),
              Marten::DB::Management::Column::Int.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ] of Marten::DB::Migration::Operation::Base,
        dependencies: [{"other_app", "other_migration"}]
      )
      migration.name.should eq "202107031819361_auto"
    end
  end

  describe "#version" do
    it "returns the initial generated migration name" do
      migration = Marten::DB::Management::Migrations::Diff::Migration.new(
        app_label: "my_app",
        name: "202107031819361",
        operations: [
          Marten::DB::Migration::Operation::CreateTable.new(
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::Int.new("foo"),
              Marten::DB::Management::Column::Int.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ] of Marten::DB::Migration::Operation::Base,
        dependencies: [{"other_app", "other_migration"}]
      )
      migration.version.should eq "202107031819361"
    end
  end

  describe "#serialize" do
    it "returns a serialized version of the generated migration" do
      migration = Marten::DB::Management::Migrations::Diff::Migration.new(
        app_label: "my_app",
        name: "202107031819361",
        operations: [
          Marten::DB::Migration::Operation::CreateTable.new(
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::Int.new("foo"),
              Marten::DB::Management::Column::Int.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ] of Marten::DB::Migration::Operation::Base,
        dependencies: [{"other_app", "other_migration"}]
      )

      time = Time.local
      Timecop.freeze(time) do
        migration.serialize.split.map(&.strip).should eq(
          (
            <<-MIGRATION
            # Generated by Marten #{Marten::VERSION} on #{time}

            class Migration::MyApp::V202107031819361 < Marten::Migration
              depends_on :other_app, :other_migration

              def plan
                create_table :test_table do
                  column :id, :big_int, primary_key: true, auto: true
                  column :foo, :int
                  column :bar, :int

                  unique_constraint :test_constraint, [:foo, :bar]
                end
              end
            end

            MIGRATION
          ).split.map(&.strip)
        )
      end
    end

    it "returns a serialized version of the generated migration with replacements configured" do
      migration = Marten::DB::Management::Migrations::Diff::Migration.new(
        app_label: "my_app",
        name: "202107031819361",
        operations: [
          Marten::DB::Migration::Operation::CreateTable.new(
            name: "test_table",
            columns: [
              Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
              Marten::DB::Management::Column::Int.new("foo"),
              Marten::DB::Management::Column::Int.new("bar"),
            ] of Marten::DB::Management::Column::Base,
            unique_constraints: [
              Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"]),
            ]
          ),
        ] of Marten::DB::Migration::Operation::Base,
        dependencies: [{"other_app", "other_migration"}],
        replacements: [{"my_app", "old_migration_1"}, {"my_app", "old_migration_2"}]
      )

      time = Time.local
      Timecop.freeze(time) do
        migration.serialize.split.map(&.strip).should eq(
          (
            <<-MIGRATION
            # Generated by Marten #{Marten::VERSION} on #{time}

            class Migration::MyApp::V202107031819361 < Marten::Migration
              depends_on :other_app, :other_migration

              replaces :my_app, :old_migration_1
              replaces :my_app, :old_migration_2

              def plan
                create_table :test_table do
                  column :id, :big_int, primary_key: true, auto: true
                  column :foo, :int
                  column :bar, :int

                  unique_constraint :test_constraint, [:foo, :bar]
                end
              end
            end

            MIGRATION
          ).split.map(&.strip)
        )
      end
    end
  end
end
