require "./spec_helper"

describe Marten::DB::Field::Duration do
  describe "::new" do
    it "initializes a duration field instance with the expected default values" do
      field = Marten::DB::Field::Duration.new("my_field")
      field.id.should eq "my_field"
      field.default.should be_nil
      field.primary_key?.should be_false
      field.blank?.should be_false
      field.null?.should be_false
      field.unique?.should be_false
      field.db_column.should eq field.id
      field.index?.should be_false
    end

    it "initializes a duration field instance with a specific default value" do
      field = Marten::DB::Field::Duration.new("my_field", default: 2.hours)
      field.id.should eq "my_field"
      field.default.should eq 2.hours
    end
  end

  describe "#default" do
    it "returns nil if no default value is specified" do
      field = Marten::DB::Field::Duration.new("my_field")
      field.default.should be_nil
    end

    it "returns the specified default value" do
      field = Marten::DB::Field::Duration.new("my_field", default: 2.hours)
      field.default.should eq 2.hours
    end
  end

  describe "#from_db" do
    it "is able to process a nil value" do
      field = Marten::DB::Field::Duration.new("my_field")
      field.from_db(nil).should be_nil
    end

    it "is able to process an Int32 value" do
      field = Marten::DB::Field::Duration.new("my_field")
      field.from_db(10000).should eq Time::Span.new(nanoseconds: 10000)
    end

    it "is able to process an Int64 value" do
      field = Marten::DB::Field::Duration.new("my_field")
      field.from_db(10000.to_i64).should eq Time::Span.new(nanoseconds: 10000)
    end

    it "is able to process a Time::Span value" do
      field = Marten::DB::Field::Duration.new("my_field")
      field.from_db(4.hours).should eq 4.hours
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Duration.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read an integer value from a DB result set" do
      field = Marten::DB::Field::Duration.new("my_field")

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 10000") do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a Time::Span
            value.should eq Time::Span.new(nanoseconds: 10000)
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::Duration.new("my_field")

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
      field = Marten::DB::Field::Duration.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::BigInt
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.auto?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      field = Marten::DB::Field::Duration.new("my_field", default: 2.hours)
      column = field.to_column
      column.default.should eq 2.hours.total_nanoseconds.to_i64
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Duration.new("my_field")
      field.to_db(nil).should be_nil
    end

    it "returns the total number of nanoseconds if the value is a time span" do
      field = Marten::DB::Field::Duration.new("my_field")
      field.to_db(2.hours).should eq 2.hours.total_nanoseconds.to_i64
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Duration.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end
end
