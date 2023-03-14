require "./spec_helper"

describe Marten::DB::Management::Migrations::Graph do
  describe "#add_node" do
    it "adds a migration to the graph" do
      migration = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration)

      node = graph.find_node(migration.id)
      node.migration.should eq migration
    end
  end

  describe "#add_dependency" do
    it "adds a dependency to a specific migration" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)

      graph.add_dependency(migration_1, migration_2.id)

      node_1 = graph.find_node(migration_1.id)
      node_2 = graph.find_node(migration_2.id)

      node_1.parents.should eq [node_2].to_set
      node_1.children.should be_empty

      node_2.parents.should be_empty
      node_2.children.should eq [node_1].to_set
    end

    it "raises if the passed migration ID does not correspond to any existing nodes" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_2)

      expect_raises(
        Marten::DB::Management::Migrations::Errors::UnknownNode,
        "Unknown node for migration ID '#{migration_1.id}'"
      ) do
        graph.add_dependency(migration_1, migration_2.id)
      end
    end

    it "raises if the passed dependency ID does not correspond to any existing nodes" do
      migration = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration)

      expect_raises(
        Marten::DB::Management::Migrations::Errors::UnknownNode,
        "Unknown node for migration ID 'unknown'"
      ) do
        graph.add_dependency(migration, "unknown")
      end
    end
  end

  describe "#ensure_acyclic_property" do
    it "does not raise if there are no circular dependencies in the graph" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      graph.add_dependency(migration_1, migration_2.id)
      graph.add_dependency(migration_1, migration_3.id)

      graph.ensure_acyclic_property.should be_nil
    end

    it "does not raise if there are no circular dependencies in the graph when migrations depend on multiple apps" do
      app_1_migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      app_2_migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new
      app_2_migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration4.new
      app_2_migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration5.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(app_2_migration_1)
      graph.add_node(app_2_migration_2)
      graph.add_node(app_2_migration_3)
      graph.add_node(app_1_migration_1)

      graph.add_dependency(app_2_migration_2, app_2_migration_1.id)
      graph.add_dependency(app_2_migration_3, app_2_migration_2.id)
      graph.add_dependency(app_2_migration_3, app_1_migration_1.id)
      graph.add_dependency(app_1_migration_1, app_2_migration_2.id)

      graph.ensure_acyclic_property.should be_nil
    end

    it "raises if there is a circular dependency in the graph" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      graph.add_dependency(migration_1, migration_2.id)
      graph.add_dependency(migration_2, migration_3.id)
      graph.add_dependency(migration_3, migration_1.id)

      expect_raises(
        Marten::DB::Management::Migrations::Errors::CircularDependency,
        "Circular dependency identified up to '#{migration_3.id}'"
      ) do
        graph.ensure_acyclic_property
      end
    end
  end

  describe "#find_node" do
    it "returns the node corresponding to a specific migration ID" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)

      graph.add_dependency(migration_1, migration_2.id)

      node = graph.find_node(migration_2.id)
      node.migration.should eq migration_2
    end

    it "raises if the node is not found" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)

      graph.add_dependency(migration_1, migration_2.id)

      expect_raises(
        Marten::DB::Management::Migrations::Errors::UnknownNode,
        "Unknown node for migration ID 'unknown'"
      ) do
        graph.find_node("unknown")
      end
    end
  end

  describe "#leaves" do
    it "returns the migration nodes that don't have any internal dependents" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_3.id)

      node_2 = graph.find_node(migration_2.id)
      node_3 = graph.find_node(migration_3.id)

      graph.leaves.should eq [node_2, node_3]
    end
  end

  describe "#path_backward" do
    it "returns an array of migration nodes to unapply migrations up to the passed migration node" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_3.id)

      node_1 = graph.find_node(migration_1.id)
      node_2 = graph.find_node(migration_2.id)
      node_3 = graph.find_node(migration_3.id)

      graph.path_backward(node_1).should eq [node_2, node_1]
      graph.path_backward(node_2).should eq [node_2]
      graph.path_backward(node_3).should eq [node_2, node_3]
    end

    it "returns an array of migration nodes to unapply migrations up to the passed migration" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_3.id)

      node_1 = graph.find_node(migration_1.id)
      node_2 = graph.find_node(migration_2.id)
      node_3 = graph.find_node(migration_3.id)

      graph.path_backward(migration_1).should eq [node_2, node_1]
      graph.path_backward(migration_2).should eq [node_2]
      graph.path_backward(migration_3).should eq [node_2, node_3]
    end
  end

  describe "#path_forward" do
    it "returns an array of migration nodes to apply migrations up to the passed migration node" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_3.id)

      node_1 = graph.find_node(migration_1.id)
      node_2 = graph.find_node(migration_2.id)
      node_3 = graph.find_node(migration_3.id)

      graph.path_forward(node_1).should eq [node_1]
      graph.path_forward(node_2).should eq [node_1, node_3, node_2]
      graph.path_forward(node_3).should eq [node_3]
    end

    it "returns an array of migration nodes to apply migrations up to the passed migration" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_3.id)

      node_1 = graph.find_node(migration_1.id)
      node_2 = graph.find_node(migration_2.id)
      node_3 = graph.find_node(migration_3.id)

      graph.path_forward(migration_1).should eq [node_1]
      graph.path_forward(migration_2).should eq [node_1, node_3, node_2]
      graph.path_forward(migration_3).should eq [node_3]
    end

    it "does not raise a circular dependency error if multiple nodes in path depends on the same older migration" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new
      migration_4 = Marten::DB::Management::Migrations::GraphSpec::TestMigration4.new
      migration_5 = Marten::DB::Management::Migrations::GraphSpec::TestMigration5.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)
      graph.add_node(migration_4)
      graph.add_node(migration_5)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_4.id)
      graph.add_dependency(migration_3, migration_2.id)
      graph.add_dependency(migration_5, migration_3.id)
      graph.add_dependency(migration_5, migration_4.id)

      node_1 = graph.find_node(migration_1.id)
      node_2 = graph.find_node(migration_2.id)
      node_3 = graph.find_node(migration_3.id)
      node_4 = graph.find_node(migration_4.id)
      node_5 = graph.find_node(migration_5.id)

      graph.path_forward(migration_5).should eq [node_1, node_4, node_2, node_3, node_5]
    end
  end

  describe "#roots" do
    it "returns the migration nodes that don't have any internal dependencies" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_3.id)

      node_1 = graph.find_node(migration_1.id)
      node_3 = graph.find_node(migration_3.id)

      graph.roots.should eq [node_1, node_3]
    end
  end

  describe "#setup_replacement" do
    it "is able to setup a replacement migration node" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new
      migration_4 = Marten::DB::Management::Migrations::GraphSpec::TestReplacementMigration1.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)
      graph.add_node(migration_4)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_3.id)
      graph.add_dependency(migration_4, migration_3.id)

      graph.setup_replacement(migration_4)

      expect_raises(Marten::DB::Management::Migrations::Errors::UnknownNode) { graph.find_node(migration_1.id) }
      expect_raises(Marten::DB::Management::Migrations::Errors::UnknownNode) { graph.find_node(migration_2.id) }

      node_3 = graph.find_node(migration_3.id)
      node_4 = graph.find_node(migration_4.id)

      node_3.parents.should be_empty
      node_3.children.should eq [node_4].to_set

      node_4.parents.should eq [node_3].to_set
      node_4.children.should be_empty
    end

    it "raises if the passed migration is not in the graph" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new
      migration_4 = Marten::DB::Management::Migrations::GraphSpec::TestReplacementMigration1.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      expect_raises(
        Marten::DB::Management::Migrations::Errors::UnknownNode,
        "Unknown node for migration ID '#{migration_4.id}'"
      ) do
        graph.setup_replacement(migration_4)
      end
    end
  end

  describe "#teardown_replacement" do
    it "is able to teardown a replacement that was configured for a specific migration node" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new
      migration_4 = Marten::DB::Management::Migrations::GraphSpec::TestReplacementMigration1.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)
      graph.add_node(migration_4)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_3.id)
      graph.add_dependency(migration_4, migration_3.id)

      graph.teardown_replacement(migration_4)

      expect_raises(Marten::DB::Management::Migrations::Errors::UnknownNode) { graph.find_node(migration_4.id) }

      node_1 = graph.find_node(migration_1.id)
      node_2 = graph.find_node(migration_2.id)
      node_3 = graph.find_node(migration_3.id)

      node_1.parents.should be_empty
      node_1.children.should eq [node_2].to_set

      node_2.parents.should eq [node_1, node_3].to_set
      node_2.children.should be_empty

      node_3.parents.should be_empty
      node_3.children.should eq [node_2].to_set
    end

    it "raises if the passed migration is not in the graph" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new
      migration_4 = Marten::DB::Management::Migrations::GraphSpec::TestReplacementMigration1.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      expect_raises(
        Marten::DB::Management::Migrations::Errors::UnknownNode,
        "Unknown node for migration ID '#{migration_4.id}'"
      ) do
        graph.teardown_replacement(migration_4)
      end
    end
  end

  describe "#to_project_state" do
    it "returns a projet state object corresponding to the graph" do
      migration_1 = Marten::DB::Management::Migrations::GraphSpec::TestMigration1.new
      migration_2 = Marten::DB::Management::Migrations::GraphSpec::TestMigration2.new
      migration_3 = Marten::DB::Management::Migrations::GraphSpec::TestMigration3.new

      graph = Marten::DB::Management::Migrations::Graph.new
      graph.add_node(migration_1)
      graph.add_node(migration_2)
      graph.add_node(migration_3)

      graph.add_dependency(migration_2, migration_1.id)
      graph.add_dependency(migration_2, migration_3.id)

      project_state = graph.to_project_state

      project_state.tables.size.should eq 3

      table_1 = project_state.get_table("graph_spec", "migration_test_table1")
      table_1.columns.map(&.name).should eq ["id", "label", "foo"]

      table_2 = project_state.get_table("graph_spec", "migration_test_table2")
      table_2.columns.map(&.name).should eq ["id", "name", "other_id", "new_id"]

      table_3 = project_state.get_table("other_graph_spec", "migration_test_table3")
      table_3.columns.map(&.name).should eq ["id", "name"]
    end
  end
end

module Marten::DB::Management::Migrations::GraphSpec
  class TestApp < Marten::App
    label :graph_spec
  end

  class OtherTestApp < Marten::App
    label :other_graph_spec
  end

  class TestMigration1 < Marten::DB::Migration
    def self.app_config
      TestApp.new
    end

    def self.migration_name
      "test_migration_name_1"
    end

    def plan
      create_table :migration_test_table1 do
        column :id, :big_int, primary_key: true, auto: true
        column :label, :string, max_size: 255
      end

      create_table :migration_test_table2 do
        column :id, :big_int, primary_key: true, auto: true
        column :name, :string, max_size: 255
        column :other_id, :reference, to_table: :migration_test_table1, to_column: :id
      end
    end
  end

  class TestMigration2 < Marten::DB::Migration
    def self.app_config
      TestApp.new
    end

    def self.migration_name
      "test_migration_name_2"
    end

    def plan
      add_column :migration_test_table1, :foo, :string, max_size: 255
      add_column :migration_test_table2, :new_id, :reference, to_table: :migration_test_table3, to_column: :id
    end
  end

  class TestMigration3 < Marten::DB::Migration
    def self.app_config
      OtherTestApp.new
    end

    def self.migration_name
      "test_migration_name_3"
    end

    def plan
      create_table :migration_test_table3 do
        column :id, :big_int, primary_key: true, auto: true
        column :name, :string, max_size: 255
      end
    end
  end

  class TestMigration4 < Marten::DB::Migration
    def self.app_config
      OtherTestApp.new
    end

    def self.migration_name
      "test_migration_name_4"
    end

    def plan
    end
  end

  class TestMigration5 < Marten::DB::Migration
    def self.app_config
      OtherTestApp.new
    end

    def self.migration_name
      "test_migration_name_5"
    end

    def plan
    end
  end

  class TestReplacementMigration1 < Marten::DB::Migration
    replaces :graph_spec, :test_migration_name_1
    replaces :graph_spec, :test_migration_name_2

    def self.app_config
      TestApp.new
    end

    def self.migration_name
      "test_replacement_migration_name_1"
    end
  end

  Marten::DB::Management::Migrations.registry.delete(TestMigration1)
  Marten::DB::Management::Migrations.registry.delete(TestMigration2)
  Marten::DB::Management::Migrations.registry.delete(TestMigration3)
  Marten::DB::Management::Migrations.registry.delete(TestMigration4)
  Marten::DB::Management::Migrations.registry.delete(TestMigration5)
  Marten::DB::Management::Migrations.registry.delete(TestReplacementMigration1)
end
