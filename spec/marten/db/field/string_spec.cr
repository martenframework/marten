require "./spec_helper"

describe Marten::DB::Field::String do
  describe "#from_db" do
    it "returns a string if the value is a string" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.from_db("foo").should eq "foo"
    end

    it "returns nil if the value is nil" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.from_db(nil).should be_nil
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read an string value from a DB result set" do
      field = Marten::DB::Field::String.new("my_field", db_column: "my_field_col", max_size: 128)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 'hello'") do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a String
            value.should eq "hello"
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::String.new("my_field", db_column: "my_field_col", max_size: 128)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#max_size" do
    it "returns the configured max size" do
      field = Marten::DB::Field::String.new("my_field", db_column: "my_field_col", max_size: 128)
      field.max_size.should eq 128
    end
  end

  describe "#min_size" do
    it "returns nil by default" do
      field = Marten::DB::Field::String.new("my_field", db_column: "my_field_col", max_size: 128)
      field.min_size.should be_nil
    end

    it "returns the configured min size" do
      field = Marten::DB::Field::String.new("my_field", db_column: "my_field_col", max_size: 128, min_size: 5)
      field.min_size.should eq 5
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::String.new("my_field", db_column: "my_field_col", max_size: 128)
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::String
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.max_size.should eq 128
      column.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128, default: "foobar")
      column = field.to_column
      column.default.should eq "foobar"
    end
  end

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.default.should be_nil
    end

    it "returns the configured default" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128, default: "foobar")
      field.default.should eq "foobar"
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.to_db(nil).should be_nil
    end

    it "returns a string value if the initial value is a string" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.to_db("hello").should eq "hello"
    end

    it "returns a string value if the initial value is a symbol" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.to_db(:hello).should eq "hello"
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end

  describe "#empty_value?" do
    it "returns true if the value is nil" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.empty_value?(nil).should be_true
    end

    it "returns true if the value is an empty string" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.empty_value?("").should be_true
    end

    it "returns true if the value is an empty symbol" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.empty_value?(:"").should be_true
    end

    it "returns false if the value is a non-empty string" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.empty_value?("hello").should be_false
    end

    it "returns false if the value is a non-empty symbol" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)
      field.empty_value?(:hello).should be_false
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::String.new("my_field", max_size: 128)

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.empty_value?(["foo", "bar"])
      end
    end
  end

  describe "#validate" do
    it "adds an error to the record if the string size is greater than the allowed max limit" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: false, max_size: 128)
      field.validate(obj, "a" * 150)

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "name"
      obj.errors.first.message.should eq "The maximum allowed length is 128"
    end

    it "adds an error to the record if the string size is lesser than the allowed min limit" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: false, min_size: 5, max_size: 128)
      field.validate(obj, "a" * 4)

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "name"
      obj.errors.first.message.should eq "The minimum allowed length is 5"
    end

    it "does not add an error to the record if the string size is equal to the allowed max limit" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: false, max_size: 128)
      field.validate(obj, "a" * 128)

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the string size is equal to the allowed min limit" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: false, min_size: 5, max_size: 128)
      field.validate(obj, "a" * 5)

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the string size is less than the allowed max limit" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: false, max_size: 128)
      field.validate(obj, "a" * 100)

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the string size is greater than the allowed min limit" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: false, min_size: 5, max_size: 128)
      field.validate(obj, "a" * 6)

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the value is nil" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: false, max_size: 128)
      field.validate(obj, nil)

      obj.errors.size.should eq 0
    end
  end
end
