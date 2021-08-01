require "./spec_helper"

describe Marten::DB::Management::ProjectState do
  describe "::from_apps" do
    it "initializes a project state from an array of apps" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      project_state.tables.find { |_, t| t.name == Post.db_table }.should be_truthy
      project_state.tables.find { |_, t| t.name == Tag.db_table }.should be_truthy
    end
  end

  describe "#clone" do
    it "returns a cloned version of the project state" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      cloned_project_state = project_state.clone

      cloned_project_state.should_not be project_state

      project_state.tables.each do |id, table_state|
        cloned_project_state.tables[id].should_not be table_state

        cloned_project_state.tables[id].columns.should eq table_state.columns
        cloned_project_state.tables[id].columns.should_not be table_state.columns
        cloned_project_state.tables[id].columns.each_with_index do |cloned_column, i|
          cloned_column.should eq table_state.columns[i]
          cloned_column.should_not be table_state.columns[i]
        end

        cloned_project_state.tables[id].unique_constraints.should eq table_state.unique_constraints
        cloned_project_state.tables[id].unique_constraints.should_not be table_state.unique_constraints
        cloned_project_state.tables[id].unique_constraints.each_with_index do |cloned_unique_constraint, i|
          cloned_unique_constraint.should eq table_state.unique_constraints[i]
          cloned_unique_constraint.should_not be table_state.unique_constraints[i]
        end
      end
    end
  end

  describe "#add_table" do
    it "adds a table to the project state" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)

      table = Marten::DB::Management::TableState.new(
        "my_app",
        "my_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [] of Marten::DB::Management::Constraint::Unique
      )
      project_state.add_table(table)

      project_state.get_table("my_app", "my_table").should eq table
    end
  end

  describe "#delete_table" do
    it "deletes a table corresponding to a given app label and table name" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      project_state.delete_table(TestApp.label, Post.db_table)
      expect_raises(KeyError) { project_state.get_table(TestApp.label, Post.db_table) }
    end
  end

  describe "#get_table" do
    it "returns the table corresponding to a given app label and table name" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)

      table = project_state.get_table(TestApp.label, Post.db_table)
      table.app_label.should eq TestApp.label
      table.name.should eq Post.db_table
    end

    it "returns the table corresponding to a given table ID" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)

      table = project_state.get_table("#{TestApp.label}_#{Post.db_table}")
      table.app_label.should eq TestApp.label
      table.name.should eq Post.db_table
    end
  end

  describe "#rename_table" do
    it "renames the table corresponding to a given app label and table name" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)

      project_state.rename_table(TestApp.label, Post.db_table, "new_name")

      table = project_state.get_table(TestApp.label, "new_name")
      table.app_label.should eq TestApp.label
      table.name.should eq "new_name"
    end
  end
end
