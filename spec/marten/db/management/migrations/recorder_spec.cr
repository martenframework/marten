require "./spec_helper"

describe Marten::DB::Management::Migrations::Recorder do
  before_all do
    Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.default).setup
  end

  before_each do
    Marten::DB::Management::Migrations::Record.filter(app: "recorder_spec").delete(raw: true)
  end

  describe "#applied_migrations" do
    it "returns all the recorded migrations" do
      migration_1 = Marten::DB::Management::Migrations::Record.create!(app: "recorder_spec", name: "migration_1")
      migration_2 = Marten::DB::Management::Migrations::Record.create!(app: "recorder_spec", name: "migration_2")

      recorder = Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.default)

      recorder.applied_migrations.filter(app: "recorder_spec").to_a.should eq [migration_1, migration_2]
    end
  end

  describe "#record" do
    it "creates a record for a specific migration object" do
      migration = Marten::DB::Management::Migrations::RecorderSpec::TestMigration.new
      recorder = Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.default)
      recorder.record(migration)

      (qs = recorder.applied_migrations.filter(app: "recorder_spec")).size.should eq 1
      qs.first!.app.should eq "recorder_spec"
      qs.first!.name.should eq "test_migration_name"
    end

    it "creates a record for a specific app label and migration name" do
      recorder = Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.default)
      recorder.record(app_label: "recorder_spec", name: "test_migration_name")

      (qs = recorder.applied_migrations.filter(app: "recorder_spec")).size.should eq 1
      qs.first!.app.should eq "recorder_spec"
      qs.first!.name.should eq "test_migration_name"
    end
  end

  describe "#unrecord" do
    it "removes the associated with a specific migration object" do
      migration = Marten::DB::Management::Migrations::RecorderSpec::TestMigration.new
      recorder = Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.default)
      recorder.record(migration)
      recorder.unrecord(migration)

      recorder.applied_migrations.exists?.should be_false
    end

    it "removes the associated with a specific app label and migration name" do
      recorder = Marten::DB::Management::Migrations::Recorder.new(Marten::DB::Connection.default)
      recorder.record(app_label: "recorder_spec", name: "test_migration_name")
      recorder.unrecord(app_label: "recorder_spec", name: "test_migration_name")

      recorder.applied_migrations.exists?.should be_false
    end
  end
end

module Marten::DB::Management::Migrations::RecorderSpec
  class TestApp < Marten::App
    label :recorder_spec
  end

  class TestMigration < Marten::DB::Migration
    def self.app_config
      TestApp.new
    end

    def self.migration_name
      "test_migration_name"
    end
  end

  Marten::DB::Management::Migrations.registry.delete(TestMigration)
end
