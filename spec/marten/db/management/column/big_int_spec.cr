require "./spec_helper"

describe Marten::DB::Management::Column::BigInt do
  describe "#==" do
    it "returns true if two column objects are the same" do
      column_1 = Marten::DB::Management::Column::BigInt.new("test")
      column_2 = column_1
      column_1.should eq column_2
    end

    it "returns true if two column objects have the same properties" do
      Marten::DB::Management::Column::BigInt.new("test").should eq(
        Marten::DB::Management::Column::BigInt.new("test")
      )

      Marten::DB::Management::Column::BigInt.new("test", null: true).should eq(
        Marten::DB::Management::Column::BigInt.new("test", null: true)
      )

      Marten::DB::Management::Column::BigInt.new("test", unique: true, default: 42).should eq(
        Marten::DB::Management::Column::BigInt.new("test", unique: true, default: 42)
      )

      Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true).should eq(
        Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true)
      )
    end

    it "returns false if two column objects don't have the same name" do
      Marten::DB::Management::Column::BigInt.new("test").should_not eq(
        Marten::DB::Management::Column::BigInt.new("other")
      )
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::BigInt.new("test", primary_key: false).should_not eq(
        Marten::DB::Management::Column::BigInt.new("test", primary_key: true)
      )
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::BigInt.new("test", null: false).should_not eq(
        Marten::DB::Management::Column::BigInt.new("test", null: true)
      )
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::BigInt.new("test", unique: false).should_not eq(
        Marten::DB::Management::Column::BigInt.new("test", unique: true)
      )
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::BigInt.new("test", index: false).should_not eq(
        Marten::DB::Management::Column::BigInt.new("test", index: true)
      )
    end

    it "returns false if two column objects don't have the same auto configuration" do
      Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true).should_not eq(
        Marten::DB::Management::Column::BigInt.new("foo", primary_key: true, auto: false)
      )
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::BigInt.new("test", default: 42).should_not eq(
        Marten::DB::Management::Column::BigInt.new("test", default: 10)
      )
    end
  end

  describe "#auto?" do
    it "returns true if the column is auto incremented" do
      column = Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true)
      column.auto?.should be_true
    end

    it "returns false if the column is not auto incremented" do
      column = Marten::DB::Management::Column::BigInt.new("id", primary_key: true)
      column.auto?.should be_false
    end
  end

  describe "#clone" do
    it "returns a cloned object" do
      column_1 = Marten::DB::Management::Column::BigInt.new("test")
      cloned_column_1 = column_1.clone
      cloned_column_1.should_not be column_1
      cloned_column_1.should eq Marten::DB::Management::Column::BigInt.new("test")

      column_2 = Marten::DB::Management::Column::BigInt.new("test", null: true)
      cloned_column_2 = column_2.clone
      cloned_column_2.should_not be column_2
      cloned_column_2.should eq Marten::DB::Management::Column::BigInt.new("test", null: true)

      column_3 = Marten::DB::Management::Column::BigInt.new("test", unique: true)
      cloned_column_3 = column_3.clone
      cloned_column_3.should_not be column_3
      cloned_column_3.should eq Marten::DB::Management::Column::BigInt.new("test", unique: true)

      column_4 = Marten::DB::Management::Column::BigInt.new("test", index: true)
      cloned_column_4 = column_4.clone
      cloned_column_4.should_not be column_4
      cloned_column_4.should eq Marten::DB::Management::Column::BigInt.new("test", index: true)

      column_5 = Marten::DB::Management::Column::BigInt.new("test", default: 42)
      cloned_column_5 = column_5.clone
      cloned_column_5.should_not be column_5
      cloned_column_5.should eq Marten::DB::Management::Column::BigInt.new("test", default: 42)
    end

    it "properly clones a primary key column with auto increment" do
      column = Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true)
      cloned_column = column.clone
      cloned_column.should_not be column
      cloned_column.should eq Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true)
    end
  end

  describe "#same_config?" do
    it "returns true if two column objects have the same properties but different names" do
      Marten::DB::Management::Column::BigInt.new("foo").same_config?(
        Marten::DB::Management::Column::BigInt.new("bar")
      ).should be_true

      Marten::DB::Management::Column::BigInt.new("foo", null: true).same_config?(
        Marten::DB::Management::Column::BigInt.new("bar", null: true)
      ).should be_true

      Marten::DB::Management::Column::BigInt.new("foo", unique: true, default: 42).same_config?(
        Marten::DB::Management::Column::BigInt.new("bar", unique: true, default: 42)
      ).should be_true

      Marten::DB::Management::Column::BigInt.new("id1", primary_key: true, auto: true).same_config?(
        Marten::DB::Management::Column::BigInt.new("id2", primary_key: true, auto: true)
      ).should be_true
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::BigInt.new("foo", primary_key: false).same_config?(
        Marten::DB::Management::Column::BigInt.new("bar", primary_key: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::BigInt.new("foo", null: false).same_config?(
        Marten::DB::Management::Column::BigInt.new("bar", null: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::BigInt.new("foo", unique: false).same_config?(
        Marten::DB::Management::Column::BigInt.new("bar", unique: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::BigInt.new("foo", index: false).same_config?(
        Marten::DB::Management::Column::BigInt.new("bar", index: true)
      ).should be_false
    end

    it "returns false if two column objects don't have the same auto configuration" do
      Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: true).same_config?(
        Marten::DB::Management::Column::BigInt.new("id", primary_key: true, auto: false)
      ).should be_false
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::BigInt.new("foo", default: 42).same_config?(
        Marten::DB::Management::Column::BigInt.new("bar", default: 10)
      ).should be_false
    end

    it "returns false if two column objects have the same properties but are of different classes" do
      Marten::DB::Management::Column::Int.new("foo").same_config?(
        Marten::DB::Management::Column::BigInt.new("foo")
      ).should be_false
    end
  end

  describe "#serialize_args" do
    it "returns the expected serialized version of a simple column" do
      column = Marten::DB::Management::Column::BigInt.new("test")
      column.serialize_args.should eq %{:test, :big_int}
    end

    it "returns the expected serialized version of a simple column that is a primary key" do
      column = Marten::DB::Management::Column::BigInt.new("test", primary_key: true)
      column.serialize_args.should eq %{:test, :big_int, primary_key: true}
    end

    it "returns the expected serialized version of a simple column that is a nullable" do
      column = Marten::DB::Management::Column::BigInt.new("test", null: true)
      column.serialize_args.should eq %{:test, :big_int, null: true}
    end

    it "returns the expected serialized version of a simple column that is unique" do
      column = Marten::DB::Management::Column::BigInt.new("test", unique: true)
      column.serialize_args.should eq %{:test, :big_int, unique: true}
    end

    it "returns the expected serialized version of a simple column that is indexed" do
      column = Marten::DB::Management::Column::BigInt.new("test", index: true)
      column.serialize_args.should eq %{:test, :big_int, index: true}
    end

    it "returns the expected serialized version of a simple column that is auto incremented" do
      column = Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true)
      column.serialize_args.should eq %{:test, :big_int, primary_key: true, auto: true}
    end

    it "returns the expected serialized version of a simple column that has a default value" do
      column = Marten::DB::Management::Column::BigInt.new("test", default: 42)
      column.serialize_args.should eq %{:test, :big_int, default: 42}
    end
  end

  describe "#sql_type" do
    it "returns the expected SQL type" do
      column = Marten::DB::Management::Column::BigInt.new("test")

      for_mysql { column.sql_type(Marten::DB::Connection.default).should eq "bigint" }
      for_postgresql { column.sql_type(Marten::DB::Connection.default).should eq "bigint" }
      for_sqlite { column.sql_type(Marten::DB::Connection.default).should eq "integer" }
    end

    it "returns the expected SQL type for a column that is auto incremented" do
      column = Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true)

      for_mysql { column.sql_type(Marten::DB::Connection.default).should eq "bigint AUTO_INCREMENT" }
      for_postgresql { column.sql_type(Marten::DB::Connection.default).should eq "bigserial" }
      for_sqlite { column.sql_type(Marten::DB::Connection.default).should eq "integer" }
    end
  end

  describe "#sql_type_suffix" do
    it "returns the expected SQL type suffix" do
      column = Marten::DB::Management::Column::BigInt.new("test")
      column.sql_type_suffix(Marten::DB::Connection.default).should be_nil
    end

    it "returns the expected SQL type suffix for a column that is auto incremented" do
      column = Marten::DB::Management::Column::BigInt.new("test", primary_key: true, auto: true)

      for_mysql { column.sql_type_suffix(Marten::DB::Connection.default).should be_nil }
      for_postgresql { column.sql_type_suffix(Marten::DB::Connection.default).should be_nil }
      for_sqlite { column.sql_type_suffix(Marten::DB::Connection.default).should eq "AUTOINCREMENT" }
    end
  end
end
