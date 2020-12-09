require "./spec_helper"

describe Marten::DB::Field::BigInt do
  describe "#from_db_result_set" do
    it "is able to read an integer value from a DB result set" do
      field = Marten::DB::Field::BigInt.new("my_field", db_column: "my_field_col", primary_key: true)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 42") do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a Int32 | Int64
            value.should eq 42
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::BigInt.new("my_field", db_column: "my_field_col", primary_key: true)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 42") do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a Int32 | Int64
            value.should eq 42
          end
        end
      end
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::BigInt.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::BigInt
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::BigInt.new("my_field")
      field.to_db(nil).should be_nil
    end

    it "returns an Int64 value if the initial value is an Int64" do
      field = Marten::DB::Field::BigInt.new("my_field")
      field.to_db(42.to_i64).should eq 42.to_i64
    end

    it "returns a casted Int64 value if the value is an Int8" do
      field = Marten::DB::Field::BigInt.new("my_field")
      field.to_db(42.to_i8).should eq 42.to_i64
    end

    it "returns a casted Int64 value if the value is an Int16" do
      field = Marten::DB::Field::BigInt.new("my_field")
      field.to_db(42.to_i16).should eq 42.to_i64
    end

    it "returns a casted Int64 value if the value is an Int32" do
      field = Marten::DB::Field::BigInt.new("my_field")
      field.to_db(42.to_i32).should eq 42.to_i64
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::BigInt.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end
end
