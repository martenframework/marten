require "./spec_helper"

describe Marten::DB::Management::Column::String do
  describe "#==" do
    it "returns true if two column objects are the same" do
      column_1 = Marten::DB::Management::Column::String.new("test", max_size: 128)
      column_2 = column_1
      column_1.should eq column_2
    end

    it "returns true if two column objects have the same properties" do
      Marten::DB::Management::Column::String.new("test", max_size: 128).should eq(
        Marten::DB::Management::Column::String.new("test", max_size: 128)
      )

      Marten::DB::Management::Column::String.new("test", max_size: 128, null: true).should eq(
        Marten::DB::Management::Column::String.new("test", max_size: 128, null: true)
      )

      Marten::DB::Management::Column::String.new("test", max_size: 128, unique: true, default: "test").should eq(
        Marten::DB::Management::Column::String.new("test", max_size: 128, unique: true, default: "test")
      )
    end

    it "returns false if two column objects don't have the same name" do
      Marten::DB::Management::Column::String.new("test", max_size: 128).should_not eq(
        Marten::DB::Management::Column::String.new("other", max_size: 128)
      )
    end

    it "returns false if two column objects don't have the same max size" do
      Marten::DB::Management::Column::String.new("test", max_size: 128).should_not eq(
        Marten::DB::Management::Column::String.new("test", max_size: 255)
      )
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::String.new("test", max_size: 128, primary_key: true).should_not eq(
        Marten::DB::Management::Column::String.new("test", max_size: 128, primary_key: false)
      )
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::String.new("test", max_size: 128, null: false).should_not eq(
        Marten::DB::Management::Column::String.new("test", max_size: 128, null: true)
      )
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::String.new("test", max_size: 128, unique: false).should_not eq(
        Marten::DB::Management::Column::String.new("test", max_size: 128, unique: true)
      )
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::String.new("test", max_size: 128, index: false).should_not eq(
        Marten::DB::Management::Column::String.new("test", max_size: 128, index: true)
      )
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::String.new("test", max_size: 128, default: "foo").should_not eq(
        Marten::DB::Management::Column::String.new("test", max_size: 128, default: "bar")
      )
    end
  end

  describe "#clone" do
    it "returns a cloned object" do
      column_1 = Marten::DB::Management::Column::String.new("test", max_size: 128)
      cloned_column_1 = column_1.clone
      cloned_column_1.should_not be column_1
      cloned_column_1.max_size.should eq 128
      cloned_column_1.should eq Marten::DB::Management::Column::String.new("test", max_size: 128)

      column_2 = Marten::DB::Management::Column::String.new("test", max_size: 128, null: true)
      cloned_column_2 = column_2.clone
      cloned_column_2.should_not be column_2
      cloned_column_2.should eq Marten::DB::Management::Column::String.new("test", max_size: 128, null: true)

      column_3 = Marten::DB::Management::Column::String.new("test", max_size: 128, unique: true)
      cloned_column_3 = column_3.clone
      cloned_column_3.should_not be column_3
      cloned_column_3.should eq Marten::DB::Management::Column::String.new("test", max_size: 128, unique: true)

      column_4 = Marten::DB::Management::Column::String.new("test", max_size: 128, index: true)
      cloned_column_4 = column_4.clone
      cloned_column_4.should_not be column_4
      cloned_column_4.should eq Marten::DB::Management::Column::String.new("test", max_size: 128, index: true)

      column_5 = Marten::DB::Management::Column::String.new("test", max_size: 128, default: 42)
      cloned_column_5 = column_5.clone
      cloned_column_5.should_not be column_5
      cloned_column_5.should eq Marten::DB::Management::Column::String.new("test", max_size: 128, default: 42)
    end
  end

  describe "#same_config?" do
    it "returns true if two column objects have different names but have the same properties" do
      Marten::DB::Management::Column::String.new("foo", max_size: 128).same_config?(
        Marten::DB::Management::Column::String.new("bar", max_size: 128)
      ).should be_true

      Marten::DB::Management::Column::String.new("foo", max_size: 128, null: true).same_config?(
        Marten::DB::Management::Column::String.new("bar", max_size: 128, null: true)
      ).should be_true

      Marten::DB::Management::Column::String.new("foo", max_size: 128, unique: true, default: "test").same_config?(
        Marten::DB::Management::Column::String.new("bar", max_size: 128, unique: true, default: "test")
      ).should be_true
    end

    it "returns false if two column objects don't have the same max size" do
      Marten::DB::Management::Column::String.new("foo", max_size: 128).same_config?(
        Marten::DB::Management::Column::String.new("bar", max_size: 255)
      ).should be_false
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::String.new("foo", max_size: 128, primary_key: true).same_config?(
        Marten::DB::Management::Column::String.new("bar", max_size: 128, primary_key: false)
      ).should be_false
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::String.new("foo", max_size: 128, null: false).same_config?(
        Marten::DB::Management::Column::String.new("bar", max_size: 128, null: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::String.new("foo", max_size: 128, unique: false).same_config?(
        Marten::DB::Management::Column::String.new("bar", max_size: 128, unique: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::String.new("foo", max_size: 128, index: false).same_config?(
        Marten::DB::Management::Column::String.new("bar", max_size: 128, index: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::String.new("foo", max_size: 128, default: "foo").same_config?(
        Marten::DB::Management::Column::String.new("bar", max_size: 128, default: "bar")
      ).should be_false
    end

    it "returns false if two column objects have the same properties but are of different classes" do
      Marten::DB::Management::Column::String.new("foo", max_size: 128).same_config?(
        Marten::DB::Management::Column::Int.new("foo")
      ).should be_false
    end
  end

  describe "#max_size" do
    it "returns the string column max size" do
      column = Marten::DB::Management::Column::String.new("test", max_size: 128)
      column.max_size.should eq 128
    end
  end

  describe "#sql_type" do
    it "returns the expected SQL type" do
      column = Marten::DB::Management::Column::String.new("test", max_size: 128)
      column.sql_type(Marten::DB::Connection.default).should eq "varchar(128)"
    end
  end

  describe "#sql_type_suffix" do
    it "returns the expected SQL type suffix" do
      column = Marten::DB::Management::Column::String.new("test", max_size: 128)
      column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
    end
  end
end
