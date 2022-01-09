require "./spec_helper"

describe Marten::DB::Field::Float do
  describe "#from_db" do
    it "is able to process a Float64 object" do
      field = Marten::DB::Field::Float.new("my_field")
      field.from_db(42.45).should be_a Float64
    end

    it "is able to process a nil value" do
      field = Marten::DB::Field::Float.new("my_field")
      field.from_db(nil).should be_nil
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Float.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read a Float32 value from a DB result set" do
      field = Marten::DB::Field::Float.new("my_field", db_column: "my_field_col", primary_key: true)

      Marten::DB::Connection.default.open do |db|
        sql = "SELECT 10.2"
        for_postgresql { sql = "SELECT CAST('10.2' as DOUBLE PRECISION)" }
        db.query(sql) do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a Float64
            value.should eq 10.2
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::Float.new("my_field", db_column: "my_field_col", primary_key: true)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::Float.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Float
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      field = Marten::DB::Field::Float.new("my_field", db_column: "my_field_col", default: 42)
      column = field.to_column
      column.default.should eq 42
    end
  end

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::Float.new("my_field")
      field.default.should be_nil
    end

    it "returns the configured default" do
      field = Marten::DB::Field::Float.new("my_field", default: 42.45)
      field.default.should eq 42.45
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Float.new("my_field")
      field.to_db(nil).should be_nil
    end

    it "returns a Float64 value if the initial value is a Float64" do
      field = Marten::DB::Field::Float.new("my_field")
      field.to_db(42.45).should be_a Float64
      field.to_db(42.45).should eq 42.45
    end

    it "returns a casted Float64 value if the value is an Int8" do
      field = Marten::DB::Field::Float.new("my_field")
      field.to_db(42.to_i8).should be_a Float64
      field.to_db(42.to_i8).should eq 42
    end

    it "returns a casted Float64 value if the value is an Int16" do
      field = Marten::DB::Field::Float.new("my_field")
      field.to_db(42.to_i16).should be_a Float64
      field.to_db(42.to_i16).should eq 42
    end

    it "returns a casted Float64 value if the value is an Int32" do
      field = Marten::DB::Field::Float.new("my_field")
      field.to_db(42).should be_a Float64
      field.to_db(42).should eq 42
    end

    it "returns a casted Float64 value if the value is an Int64" do
      field = Marten::DB::Field::Float.new("my_field")
      field.to_db(42.to_i64).should be_a Float64
      field.to_db(42.to_i64).should eq 42
    end

    it "returns a casted Float64 value if the value is a Float32" do
      field = Marten::DB::Field::Float.new("my_field")
      field.to_db(42.45.to_f32).should be_a Float64
      field.to_db(42.45.to_f32).should eq 42.45.to_f32.to_f64
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Float.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end
end
