require "./spec_helper"

describe Marten::DB::Management::Migrations do
  describe "::register" do
    after_each do
      Marten::DB::Management::Migrations.registry.delete(Marten::DB::Management::MigrationsSpec::TestMigration)
    end

    it "allows to append a migration class to the migrations registry" do
      Marten::DB::Management::Migrations.register(Marten::DB::Management::MigrationsSpec::TestMigration)
      Marten::DB::Management::Migrations.registry.last.should eq Marten::DB::Management::MigrationsSpec::TestMigration
    end
  end
end

module Marten::DB::Management::MigrationsSpec
  class TestMigration < Marten::DB::Migration
    def self.app_config
      TestApp.new
    end
  end

  Marten::DB::Management::Migrations.registry.delete(TestMigration)
end
