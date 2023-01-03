require "./spec_helper"

describe Marten::DB::Management::TableState do
  describe "::from_model" do
    it "allows to initialize a table state from a given model" do
      table_state = Marten::DB::Management::TableState.from_model(Post)

      table_state.app_label.should eq Post.app_config.label
      table_state.name.should eq Post.db_table

      table_state.columns.each do |column|
        Post.fields.find { |f| f.db_column == column.name }.should be_truthy
      end

      table_state.unique_constraints.size.should eq Post.db_unique_constraints.size
      table_state.unique_constraints.each do |unique_constraint|
        original_constraint = Post.db_unique_constraints.find { |c| c.name == unique_constraint.name }
        original_constraint.should be_truthy
        unique_constraint.column_names.should eq original_constraint.not_nil!.fields.map(&.db_column)
      end

      table_state.indexes.size.should eq Post.db_indexes.size
      table_state.indexes.each do |index|
        original_index = Post.db_indexes.find { |i| i.name == index.name }
        original_index.should be_truthy
        index.column_names.should eq original_index.not_nil!.fields.map(&.db_column)
      end
    end
  end

  describe "::gen_id" do
    it "returns a table state ID from an app label and table name" do
      Marten::DB::Management::TableState.gen_id("app_label", "table_name").should eq "app_label_table_name"
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

  describe "#indexes" do
    it "returns the table indexes" do
      table_state = Marten::DB::Management::TableState.from_model(Post)

      table_state.indexes.size.should eq Post.db_indexes.size
      table_state.indexes.each do |index|
        original_index = Post.db_indexes.find { |i| i.name == index.name }
        original_index.should be_truthy
        index.column_names.should eq original_index.not_nil!.fields.map(&.db_column)
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

  describe "#add_index" do
    it "adds an index to the table state" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "my_table",
        [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )

      index = Marten::DB::Management::Index.new(name: "test_index", column_names: ["foo", "bar"])

      table_state.add_index(index)

      table_state.indexes.should eq [index]
    end
  end

  describe "#add_unique_constraint" do
    it "adds a unique constraint to the table state" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "my_table",
        [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        [] of Marten::DB::Management::Constraint::Unique
      )

      unique_constraint = Marten::DB::Management::Constraint::Unique.new(name: "cname", column_names: ["foo", "bar"])

      table_state.add_unique_constraint(unique_constraint)

      table_state.unique_constraints.should eq [unique_constraint]
    end
  end

  describe "#change_column" do
    it "changes the column in the considered table state" do
      old_column = Marten::DB::Management::Column::Int.new("foo")
      new_column = Marten::DB::Management::Column::String.new("foo", max_size: 100)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "my_table",
        [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          old_column,
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        [] of Marten::DB::Management::Constraint::Unique
      )

      table_state.change_column(new_column)

      table_state.columns.includes?(old_column).should be_false
      table_state.columns.includes?(new_column).should be_true
    end

    it "changes the column if it is at the beginning of the array of columns" do
      old_column = Marten::DB::Management::Column::Int.new("foo")
      new_column = Marten::DB::Management::Column::String.new("foo", max_size: 100)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "my_table",
        [
          old_column,
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        [] of Marten::DB::Management::Constraint::Unique
      )

      table_state.change_column(new_column)

      table_state.columns.includes?(old_column).should be_false
      table_state.columns.includes?(new_column).should be_true
    end

    it "changes the column if it is at the end of the array of columns" do
      old_column = Marten::DB::Management::Column::Int.new("foo")
      new_column = Marten::DB::Management::Column::String.new("foo", max_size: 100)

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "my_table",
        [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("bar"),
          old_column,
        ] of Marten::DB::Management::Column::Base,
        [] of Marten::DB::Management::Constraint::Unique
      )

      table_state.change_column(new_column)

      table_state.columns.includes?(old_column).should be_false
      table_state.columns.includes?(new_column).should be_true
    end

    it "raises NilAssertionError if the column is not found" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      expect_raises(NilAssertionError) do
        table_state.change_column(Marten::DB::Management::Column::Int.new("unknown"))
      end
    end
  end

  describe "#get_column" do
    it "returns the column corresponding to the passed name" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      table_state.add_column(Marten::DB::Management::Column::Int.new("test_number"))
      table_state.get_column("test_number").name.should eq "test_number"
    end

    it "raises Enumerable::NotFoundError if the column is not found" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      expect_raises(Enumerable::NotFoundError) do
        table_state.get_column("unknown")
      end
    end
  end

  describe "#get_index" do
    it "returns the index corresponding to the passed name" do
      index = Marten::DB::Management::Index.new("test_index", ["foo", "bar"])

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        indexes: [index]
      )

      table_state.get_index("test_index").should eq index
    end

    it "raises Enumerable::NotFoundError if the index is not found" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      expect_raises(Enumerable::NotFoundError) do
        table_state.get_index("unknown")
      end
    end
  end

  describe "#get_unique_constraint" do
    it "returns the unique constraint corresponding to the passed name" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new("test_constraint", ["foo", "bar"])

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "operation_test_table",
        columns: [
          Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true),
          Marten::DB::Management::Column::BigInt.new("foo"),
          Marten::DB::Management::Column::BigInt.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        unique_constraints: [unique_constraint]
      )

      table_state.get_unique_constraint("test_constraint").should eq unique_constraint
    end

    it "raises Enumerable::NotFoundError if the unique constraint is not found" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      expect_raises(Enumerable::NotFoundError) do
        table_state.get_unique_constraint("unknown")
      end
    end
  end

  describe "#id" do
    it "returns the table state ID" do
      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "my_table",
        [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base
      )
      table_state.id.should eq "my_app_my_table"
    end
  end

  describe "#remove_column" do
    it "removes the passed column from the table state" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)

      column = Marten::DB::Management::Column::Int.new("test_number")
      table_state.add_column(column)

      table_state.remove_column(column)

      expect_raises(Enumerable::NotFoundError) do
        table_state.get_column("test_number")
      end
    end

    it "removes the passed column name from the table state" do
      table_state = Marten::DB::Management::TableState.from_model(TestUser)
      table_state.add_column(Marten::DB::Management::Column::Int.new("test_number"))

      table_state.remove_column("test_number")

      expect_raises(Enumerable::NotFoundError) do
        table_state.get_column("test_number")
      end
    end
  end

  describe "#remove_index" do
    it "removes the passed index from the table state" do
      index = Marten::DB::Management::Index.new(name: "test_index", column_names: ["foo", "bar"])

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "my_table",
        [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        indexes: [index]
      )

      table_state.remove_index(index)

      table_state.indexes.should be_empty
    end
  end

  describe "#remove_unique_constraint" do
    it "removes the passed unique constraint from the table state" do
      unique_constraint = Marten::DB::Management::Constraint::Unique.new(name: "cname", column_names: ["foo", "bar"])

      table_state = Marten::DB::Management::TableState.new(
        "my_app",
        "my_table",
        [
          Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true),
          Marten::DB::Management::Column::Int.new("foo"),
          Marten::DB::Management::Column::Int.new("bar"),
        ] of Marten::DB::Management::Column::Base,
        [unique_constraint]
      )

      table_state.remove_unique_constraint(unique_constraint)

      table_state.unique_constraints.should be_empty
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
