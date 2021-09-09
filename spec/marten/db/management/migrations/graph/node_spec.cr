require "./spec_helper"

describe Marten::DB::Management::Migrations::Graph::Node do
  describe "#add_child" do
    it "adds a child to a node" do
      migration_1 = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration1.new
      node_1 = Marten::DB::Management::Migrations::Graph::Node.new(migration_1)

      migration_2 = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration2.new
      node_2 = Marten::DB::Management::Migrations::Graph::Node.new(migration_2)
      node_2.add_child(node_1)

      node_2.children.should eq [node_1].to_set
    end
  end

  describe "#add_parent" do
    it "adds a parent to a node" do
      migration_1 = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration1.new
      node_1 = Marten::DB::Management::Migrations::Graph::Node.new(migration_1)

      migration_2 = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration2.new
      node_2 = Marten::DB::Management::Migrations::Graph::Node.new(migration_2)
      node_2.add_parent(node_1)

      node_2.parents.should eq [node_1].to_set
    end
  end

  describe "#children" do
    it "returns an empty array of the graph node does not have any children" do
      migration = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration1.new
      node = Marten::DB::Management::Migrations::Graph::Node.new(migration)
      node.children.should be_empty
    end

    it "returns the array of the underlying children" do
      migration_1 = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration1.new
      node_1 = Marten::DB::Management::Migrations::Graph::Node.new(migration_1)

      migration_2 = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration2.new
      node_2 = Marten::DB::Management::Migrations::Graph::Node.new(migration_2)
      node_2.add_child(node_1)

      node_2.children.should eq [node_1].to_set
    end
  end

  describe "#parents" do
    it "returns an empty array of the graph node does not have any parents" do
      migration = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration1.new
      node = Marten::DB::Management::Migrations::Graph::Node.new(migration)
      node.parents.should be_empty
    end

    it "returns the array of the node parents" do
      migration_1 = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration1.new
      node_1 = Marten::DB::Management::Migrations::Graph::Node.new(migration_1)

      migration_2 = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration2.new
      node_2 = Marten::DB::Management::Migrations::Graph::Node.new(migration_2)
      node_2.add_parent(node_1)

      node_2.parents.should eq [node_1].to_set
    end
  end

  describe "#migration" do
    it "returns the associated migration" do
      migration = Marten::DB::Management::Migrations::Graph::NodeSpec::TestMigration1.new
      node = Marten::DB::Management::Migrations::Graph::Node.new(migration)
      node.migration.should eq migration
    end
  end
end

module Marten::DB::Management::Migrations::Graph::NodeSpec
  class TestApp < Marten::App
    label :recorder_spec
  end

  class TestMigration1 < Marten::DB::Migration
    def self.app_config
      TestApp.new
    end

    def self.migration_name
      "test_migration_name_1"
    end
  end

  class TestMigration2 < Marten::DB::Migration
    def self.app_config
      TestApp.new
    end

    def self.migration_name
      "test_migration_name_2"
    end
  end

  Marten::DB::Management::Migrations.registry.delete(TestMigration1)
  Marten::DB::Management::Migrations.registry.delete(TestMigration2)
end
