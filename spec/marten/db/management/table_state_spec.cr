require "./spec_helper"

describe Marten::DB::Management::TableState do
  describe "::from_model" do
    it "allows to initialize a table state from a given model" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)

      table_state.app_label.should eq TestUser.app_config.label
      table_state.name.should eq TestUser.db_table

      table_state.columns.each do |column|
        TestUser.fields.find { |f| f.db_column == column.name }.should be_truthy
      end

      table_state.unique_constraints.each do |unique_constraint|
        original_constraint = TestUser.db_unique_constraints.find { |c| c.name == unique_constraint }
        original_constraint.should be_truthy
        unique_constraint.column_names.should eq original_constraint.not_nil!.fields.map(&.db_column)
      end
    end
  end

  describe "#app_label" do
    it "returns the app config label of the table" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      table_state.app_label.should eq TestUser.app_config.label
    end
  end

  describe "#app_label" do
    it "returns the table name" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      table_state.name.should eq TestUser.db_table
    end
  end

  describe "#columns" do
    it "returns the table columns" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)

      table_state.columns.each do |column|
        TestUser.fields.find { |f| f.db_column == column.name }.should be_truthy
      end
    end
  end

  describe "#unique_constraints" do
    it "returns the table unique constraints" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)

      table_state.unique_constraints.each do |unique_constraint|
        original_constraint = TestUser.db_unique_constraints.find { |c| c.name == unique_constraint }
        original_constraint.should be_truthy
        unique_constraint.column_names.should eq original_constraint.not_nil!.fields.map(&.db_column)
      end
    end
  end

  describe "#add_column" do
    it "adds a column to the table state" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      table_state.add_column(Marten::DB::Management::Column::Int.new("test_number"))
      table_state.columns.last.name.should eq "test_number"
    end
  end

  describe "#get_column" do
    it "returns the column corresponding to the passed name" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      table_state.add_column(Marten::DB::Management::Column::Int.new("test_number"))
      table_state.get_column("test_number").name.should eq "test_number"
    end

    it "raises NilAssertionError if the column is not found" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      expect_raises(NilAssertionError) { table_state.get_column("unknown") }
    end
  end

  describe "#remove_column" do
    it "removes the passed column from the table state" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)

      column = Marten::DB::Management::Column::Int.new("test_number")
      table_state.add_column(column)

      table_state.remove_column(column)

      expect_raises(NilAssertionError) { table_state.get_column("test_number") }
    end

    it "removes the passed column name from the table state" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      table_state.add_column(Marten::DB::Management::Column::Int.new("test_number"))

      table_state.remove_column("test_number")

      expect_raises(NilAssertionError) { table_state.get_column("test_number") }
    end
  end

  describe "#rename_column" do
    it "allows to rename a column" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      table_state.add_column(Marten::DB::Management::Column::Int.new("test_number"))

      table_state.rename_column("test_number", "test_number_renamed")

      table_state.get_column("test_number_renamed").should be_truthy
    end
  end

  describe "#clone" do
    it "clones the considered table state" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      cloned_table_state = table_state.clone

      cloned_table_state.should_not be table_state

      cloned_table_state.app_label.should eq table_state.app_label
      cloned_table_state.name.should eq table_state.name

      cloned_table_state.columns.should eq table_state.columns
      cloned_table_state.columns.should_not be table_state.columns
      cloned_table_state.columns.each_with_index do |cloned_column, i|
        cloned_column.should eq table_state.columns[i]
        cloned_column.should_not be table_state.columns[i]
      end

      cloned_table_state.unique_constraints.should eq table_state.unique_constraints
      cloned_table_state.unique_constraints.should_not be table_state.unique_constraints
      cloned_table_state.unique_constraints.each_with_index do |cloned_unique_constraint, i|
        cloned_unique_constraint.should eq table_state.unique_constraints[i]
        cloned_unique_constraint.should_not be table_state.unique_constraints[i]
      end
    end
  end
end