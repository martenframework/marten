require "./spec_helper"

describe Marten::DB::Management::Column::Base do
  describe "#default" do
    it "returns nil by default" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test")
      column.default.should be_nil
    end

    it "returns the specified default value" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test", default: 42)
      column.default.should eq 42
    end
  end

  describe "#name" do
    it "returns the column name" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test")
      column.name.should eq "test"
    end
  end

  describe "#name=" do
    it "allows to change the column name" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test")
      column.name = "updated"
      column.name.should eq "updated"
    end
  end

  describe "#primary_key=" do
    it "allows to make the the column a primary key or not" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test")

      column.primary_key = true
      column.primary_key?.should be_true

      column.primary_key = false
      column.primary_key?.should be_false
    end
  end

  describe "#==" do
    it "returns true if two column objects are the same" do
      column_1 = Marten::DB::Management::Column::BaseSpec::Test.new("test")
      column_2 = column_1
      column_1.should eq column_2
    end

    it "returns true if two column objects have the same properties" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test").should eq(
        Marten::DB::Management::Column::BaseSpec::Test.new("test")
      )

      Marten::DB::Management::Column::BaseSpec::Test.new("test", null: true).should eq(
        Marten::DB::Management::Column::BaseSpec::Test.new("test", null: true)
      )

      Marten::DB::Management::Column::BaseSpec::Test.new("test", unique: true, default: 42).should eq(
        Marten::DB::Management::Column::BaseSpec::Test.new("test", unique: true, default: 42)
      )
    end

    it "returns false if two column objects don't have the same name" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test").should_not eq(
        Marten::DB::Management::Column::BaseSpec::Test.new("other")
      )
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", primary_key: false).should_not eq(
        Marten::DB::Management::Column::BaseSpec::Test.new("test", primary_key: true)
      )
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", null: false).should_not eq(
        Marten::DB::Management::Column::BaseSpec::Test.new("test", null: true)
      )
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", unique: false).should_not eq(
        Marten::DB::Management::Column::BaseSpec::Test.new("test", unique: true)
      )
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", index: false).should_not eq(
        Marten::DB::Management::Column::BaseSpec::Test.new("test", index: true)
      )
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", default: 42).should_not eq(
        Marten::DB::Management::Column::BaseSpec::Test.new("test", default: 10)
      )
    end
  end

  describe "#same_config?" do
    it "returns true if two column objects have the same properties but different names" do
      Marten::DB::Management::Column::BaseSpec::Test.new("foo").same_config?(
        Marten::DB::Management::Column::BaseSpec::Test.new("bar")
      ).should be_true

      Marten::DB::Management::Column::BaseSpec::Test.new("foo", null: true).same_config?(
        Marten::DB::Management::Column::BaseSpec::Test.new("bar", null: true)
      ).should be_true

      Marten::DB::Management::Column::BaseSpec::Test.new("foo", unique: true, default: 42).same_config?(
        Marten::DB::Management::Column::BaseSpec::Test.new("bar", unique: true, default: 42)
      ).should be_true
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::BaseSpec::Test.new("foo", primary_key: false).same_config?(
        Marten::DB::Management::Column::BaseSpec::Test.new("bar", primary_key: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::BaseSpec::Test.new("foo", null: false).same_config?(
        Marten::DB::Management::Column::BaseSpec::Test.new("bar", null: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::BaseSpec::Test.new("foo", unique: false).same_config?(
        Marten::DB::Management::Column::BaseSpec::Test.new("bar", unique: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::BaseSpec::Test.new("foo", index: false).same_config?(
        Marten::DB::Management::Column::BaseSpec::Test.new("bar", index: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::BaseSpec::Test.new("foo", default: 42).same_config?(
        Marten::DB::Management::Column::BaseSpec::Test.new("bar", default: 10)
      ).should be_false
    end

    it "returns false if two column objects have the same properties but are of different classes" do
      Marten::DB::Management::Column::BigInt.new("foo").same_config?(
        Marten::DB::Management::Column::Int.new("foo")
      ).should be_false
    end
  end

  describe "#index?" do
    it "returns true when the column is indexed" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", index: true).index?.should be_true
    end

    it "returns false when the column is indexed" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", index: false).index?.should be_false
    end
  end

  describe "#null?" do
    it "returns true when the column is nullable" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", null: true).null?.should be_true
    end

    it "returns false when the column is not nullable" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", null: false).null?.should be_false
    end
  end

  describe "#primary_key?" do
    it "returns true when the column is a primary key" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", primary_key: true).primary_key?.should be_true
    end

    it "returns false when the column is not a primary key" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", primary_key: false).primary_key?.should be_false
    end
  end

  describe "#serialize_args" do
    it "returns the expected serialized version of a simple column" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test")
      column.serialize_args.should eq %{:test, :test_col}
    end

    it "returns the expected serialized version of a simple column that is a primary key" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test", primary_key: true)
      column.serialize_args.should eq %{:test, :test_col, primary_key: true}
    end

    it "returns the expected serialized version of a simple column that is a nullable" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test", null: true)
      column.serialize_args.should eq %{:test, :test_col, null: true}
    end

    it "returns the expected serialized version of a simple column that is unique" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test", unique: true)
      column.serialize_args.should eq %{:test, :test_col, unique: true}
    end

    it "returns the expected serialized version of a simple column that is indexed" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test", index: true)
      column.serialize_args.should eq %{:test, :test_col, index: true}
    end

    it "returns the expected serialized version of a simple column that has a default value" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test", default: 42)
      column.serialize_args.should eq %{:test, :test_col, default: 42}
    end
  end

  describe "#sql_type_suffix" do
    it "returns nil by default" do
      column = Marten::DB::Management::Column::BaseSpec::Test.new("test")
      column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
    end
  end

  describe "#type" do
    it "returns the column type identifier" do
      column = Marten::DB::Management::Column::Int.new("test")
      column.type.should eq "int"
    end
  end

  describe "#unique?" do
    it "returns true when the column is unique" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", unique: true).unique?.should be_true
    end

    it "returns false when the column is not unique" do
      Marten::DB::Management::Column::BaseSpec::Test.new("test", unique: false).unique?.should be_false
    end
  end
end

module Marten::DB::Management::Column::BaseSpec
  class Test < Marten::DB::Management::Column::Base
    def clone
      self.class.new(@name, @primary_key, @null, @unique, @index, @default)
    end

    def sql_quoted_default_value(connection : Connection::Base) : ::String?
      @default.to_s
    end

    def sql_type(connection : Connection::Base) : ::String
      "bigint"
    end

    def type
      "test_col"
    end
  end
end
