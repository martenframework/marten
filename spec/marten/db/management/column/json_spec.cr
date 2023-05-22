require "./spec_helper"

describe Marten::DB::Management::Column::JSON do
  describe "#==" do
    it "returns true if two column objects are the same" do
      column_1 = Marten::DB::Management::Column::JSON.new("test")
      column_2 = column_1
      column_1.should eq column_2
    end

    it "returns true if two column objects have the same properties" do
      Marten::DB::Management::Column::JSON.new("test").should eq(
        Marten::DB::Management::Column::JSON.new("test")
      )

      Marten::DB::Management::Column::JSON.new("test", null: true).should eq(
        Marten::DB::Management::Column::JSON.new("test", null: true)
      )

      Marten::DB::Management::Column::JSON.new("test", unique: true, default: "test").should eq(
        Marten::DB::Management::Column::JSON.new("test", unique: true, default: "test")
      )
    end

    it "returns false if two column objects don't have the same name" do
      Marten::DB::Management::Column::JSON.new("test").should_not eq(
        Marten::DB::Management::Column::JSON.new("other")
      )
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::JSON.new("test", primary_key: true).should_not eq(
        Marten::DB::Management::Column::JSON.new("test", primary_key: false)
      )
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::JSON.new("test", null: false).should_not eq(
        Marten::DB::Management::Column::JSON.new("test", null: true)
      )
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::JSON.new("test", unique: false).should_not eq(
        Marten::DB::Management::Column::JSON.new("test", unique: true)
      )
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::JSON.new("test", index: false).should_not eq(
        Marten::DB::Management::Column::JSON.new("test", index: true)
      )
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::JSON.new("test", default: "foo").should_not eq(
        Marten::DB::Management::Column::JSON.new("test", default: "bar")
      )
    end
  end

  describe "#clone" do
    it "returns a cloned object" do
      column_1 = Marten::DB::Management::Column::JSON.new("test")
      cloned_column_1 = column_1.clone
      cloned_column_1.should_not be column_1
      cloned_column_1.should eq Marten::DB::Management::Column::JSON.new("test")

      column_2 = Marten::DB::Management::Column::JSON.new("test", null: true)
      cloned_column_2 = column_2.clone
      cloned_column_2.should_not be column_2
      cloned_column_2.should eq Marten::DB::Management::Column::JSON.new("test", null: true)

      column_3 = Marten::DB::Management::Column::JSON.new("test", unique: true)
      cloned_column_3 = column_3.clone
      cloned_column_3.should_not be column_3
      cloned_column_3.should eq Marten::DB::Management::Column::JSON.new("test", unique: true)

      column_4 = Marten::DB::Management::Column::JSON.new("test", index: true)
      cloned_column_4 = column_4.clone
      cloned_column_4.should_not be column_4
      cloned_column_4.should eq Marten::DB::Management::Column::JSON.new("test", index: true)

      column_5 = Marten::DB::Management::Column::JSON.new("test", default: 42)
      cloned_column_5 = column_5.clone
      cloned_column_5.should_not be column_5
      cloned_column_5.should eq Marten::DB::Management::Column::JSON.new("test", default: 42)
    end
  end

  describe "#same_config?" do
    it "returns true if two column objects have different names but have the same properties" do
      Marten::DB::Management::Column::JSON.new("foo").same_config?(
        Marten::DB::Management::Column::JSON.new("bar")
      ).should be_true

      Marten::DB::Management::Column::JSON.new("foo", null: true).same_config?(
        Marten::DB::Management::Column::JSON.new("bar", null: true)
      ).should be_true

      Marten::DB::Management::Column::JSON.new("foo", unique: true, default: "test").same_config?(
        Marten::DB::Management::Column::JSON.new("bar", unique: true, default: "test")
      ).should be_true
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::JSON.new("foo", primary_key: true).same_config?(
        Marten::DB::Management::Column::JSON.new("bar", primary_key: false)
      ).should be_false
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::JSON.new("foo", null: false).same_config?(
        Marten::DB::Management::Column::JSON.new("bar", null: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::JSON.new("foo", unique: false).same_config?(
        Marten::DB::Management::Column::JSON.new("bar", unique: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::JSON.new("foo", index: false).same_config?(
        Marten::DB::Management::Column::JSON.new("bar", index: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::JSON.new("foo", default: "foo").same_config?(
        Marten::DB::Management::Column::JSON.new("bar", default: "bar")
      ).should be_false
    end

    it "returns false if two column objects have the same properties but are of different classes" do
      Marten::DB::Management::Column::JSON.new("foo").same_config?(
        Marten::DB::Management::Column::Int.new("foo")
      ).should be_false
    end
  end

  describe "#sql_type" do
    it "returns the expected SQL type" do
      column = Marten::DB::Management::Column::JSON.new("test")
      for_mysql { column.sql_type(Marten::DB::Connection.default).should eq "text" }
      for_postgresql { column.sql_type(Marten::DB::Connection.default).should eq "jsonb" }
      for_sqlite { column.sql_type(Marten::DB::Connection.default).should eq "text" }
    end
  end

  describe "#sql_type_suffix" do
    it "returns the expected SQL type suffix" do
      project_state = Marten::DB::Management::ProjectState.from_apps(Marten.apps.app_configs)
      column = Marten::DB::Management::Column::JSON.new("test")
      column.contribute_to_project(project_state)

      column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
    end
  end
end
