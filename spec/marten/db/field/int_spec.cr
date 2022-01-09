require "./spec_helper"

describe Marten::DB::Field::Int do
  describe "#auto?" do
    it "returns true if the field is auto incremented" do
      field = Marten::DB::Field::Int.new("my_field", primary_key: true, auto: true)
      field.auto?.should be_true
    end

    it "returns false if the field is not auto incremented" do
      field = Marten::DB::Field::Int.new("my_field")
      field.auto?.should be_false
    end
  end

  describe "#from_db" do
    it "returns an Int32 if the value is an Int64" do
      field = Marten::DB::Field::Int.new("my_field")
      result = field.from_db(42)
      result.should eq 42
      result.should be_a Int32
    end

    it "returns an Int32 if the value is an Int32" do
      field = Marten::DB::Field::Int.new("my_field")
      result = field.from_db(42.to_i64)
      result.should eq 42
      result.should be_a Int32
    end

    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Int.new("my_field")
      field.from_db(nil).should be_nil
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Int.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read an integer value from a DB result set" do
      field = Marten::DB::Field::Int.new("my_field", db_column: "my_field_col", primary_key: true)

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
      field = Marten::DB::Field::Int.new("my_field", db_column: "my_field_col", primary_key: true)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#perform_validation" do
    it "does not add any errors for nil values when the field is auto incremented" do
      obj = Tag.new(id: nil)

      field = Marten::DB::Field::Int.new("id", primary_key: true, auto: true)
      field.perform_validation(obj)

      obj.errors.size.should eq 0
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::Int.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Int
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.auto?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "returns the expected column for a primary key with auto increment" do
      field = Marten::DB::Field::Int.new("my_field", primary_key: true, auto: true)
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Int
      column.name.should eq "my_field"
      column.primary_key?.should be_true
      column.auto?.should be_true
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      field = Marten::DB::Field::Int.new("my_field", db_column: "my_field_col", default: 42)
      column = field.to_column
      column.default.should eq 42
    end
  end

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::Int.new("my_field")
      field.default.should be_nil
    end

    it "returns the configured default" do
      field = Marten::DB::Field::Int.new("my_field", default: 42)
      field.default.should eq 42
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Int.new("my_field")
      field.to_db(nil).should be_nil
    end

    it "returns an Int32 value if the initial value is an Int32" do
      field = Marten::DB::Field::Int.new("my_field")
      field.to_db(42).should eq 42
    end

    it "returns a casted Int32 value if the value is an Int8" do
      field = Marten::DB::Field::Int.new("my_field")
      field.to_db(42.to_i8).should eq 42
    end

    it "returns a casted Int32 value if the value is an Int16" do
      field = Marten::DB::Field::Int.new("my_field")
      field.to_db(42.to_i16).should eq 42
    end

    it "returns a casted Int32 value if the value is an Int64" do
      field = Marten::DB::Field::Int.new("my_field")
      field.to_db(42.to_i64).should eq 42
    end

    it "returns a casted Int64 value if the value is a valid integer expressed as a string" do
      field = Marten::DB::Field::Int.new("my_field")
      field.to_db("42").should eq 42
    end

    it "raises UnexpectedFieldValue if the value is a string that cannot be converted to an Int32" do
      field = Marten::DB::Field::Int.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db("hello world")
      end
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Int.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end
end
