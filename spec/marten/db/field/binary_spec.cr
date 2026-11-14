require "./spec_helper"

describe Marten::DB::Field::Binary do
  describe "#from_db" do
    it "returns a copy of the byte slice" do
      field = Marten::DB::Field::Binary.new("my_field")
      original = Bytes[0, 255, 97]

      value = field.from_db(original).as(Bytes)
      original[0] = 9_u8

      value.should eq Bytes[0, 255, 97]
    end

    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Binary.new("my_field")
      field.from_db(nil).should be_nil
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Binary.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db("payload")
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read a binary value from a DB result set" do
      field = Marten::DB::Field::Binary.new("my_field", db_column: "my_field_col")
      payload = Bytes[0, 255, 97]

      Marten::DB::Field::BinarySpec.with_binary_read_table do |db|
        Marten::DB::Field::BinarySpec.insert_binary_value(db, payload)

        db.query("SELECT value FROM binary_field_read_spec") do |rs|
          rs.each do
            field.from_db_result_set(rs).should eq payload
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::Binary.new("my_field", db_column: "my_field_col")

      Marten::DB::Field::BinarySpec.with_binary_read_table do |db|
        db.exec("INSERT INTO binary_field_read_spec (value) VALUES (NULL)")

        db.query("SELECT value FROM binary_field_read_spec") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::Binary.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Binary
      column.not_nil!.name.should eq "my_field_col"
      column.not_nil!.primary_key?.should be_false
      column.not_nil!.null?.should be_false
      column.not_nil!.unique?.should be_false
      column.not_nil!.index?.should be_false
      column.not_nil!.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      default_val = Bytes[1, 2, 3]
      field = Marten::DB::Field::Binary.new("my_field", default: default_val)
      column = field.to_column
      column.not_nil!.default.should eq default_val
    end
  end

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::Binary.new("my_field")
      field.default.should be_nil
    end

    it "returns the configured default" do
      default_val = Bytes[1, 2, 3]
      field = Marten::DB::Field::Binary.new("my_field", default: default_val)
      field.default.should eq default_val
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Binary.new("my_field")
      field.to_db(nil).should be_nil
    end

    it "returns the byte slice" do
      field = Marten::DB::Field::Binary.new("my_field")
      payload = Bytes[0, 255, 97]
      field.to_db(payload).should eq payload
    end

    it "returns an empty byte slice that is distinct from null" do
      field = Marten::DB::Field::Binary.new("my_field")
      value = field.to_db(Bytes.empty).as(Bytes)
      value.empty?.should be_true
      value.to_unsafe.null?.should be_false
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Binary.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db("payload")
      end
    end
  end

  describe "#empty_value?" do
    it "returns true if the value is nil" do
      field = Marten::DB::Field::Binary.new("my_field")
      field.empty_value?(nil).should be_true
    end

    it "returns true if the value is an empty byte slice" do
      field = Marten::DB::Field::Binary.new("my_field")
      field.empty_value?(Bytes.empty).should be_true
    end

    it "returns false if the value is a non-empty byte slice" do
      field = Marten::DB::Field::Binary.new("my_field")
      field.empty_value?(Bytes[1]).should be_false
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Binary.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.empty_value?("payload")
      end
    end
  end
end

module Marten::DB::Field::BinarySpec
  def self.insert_binary_value(db : ::DB::Connection, payload : Bytes)
    index = Marten::DB::Connection.default.parameter_id_for_ordered_argument(1)
    db.exec("INSERT INTO binary_field_read_spec (value) VALUES (#{index})", args: [payload])
  end

  def self.with_binary_read_table(&)
    Marten::DB::Connection.default.open do |db|
      db.exec("DROP TABLE IF EXISTS binary_field_read_spec")
      db.exec("CREATE TABLE binary_field_read_spec (value #{binary_column_type})")

      begin
        yield db
      ensure
        db.exec("DROP TABLE IF EXISTS binary_field_read_spec")
      end
    end
  end

  private def self.binary_column_type
    column = Marten::DB::Management::Column::Binary.new("value")
    column.sql_type(Marten::DB::Connection.default)
  end
end
