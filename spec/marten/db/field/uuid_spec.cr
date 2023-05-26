require "./spec_helper"

describe Marten::DB::Field::UUID do
  describe "#from_db" do
    it "returns a UUI object if the value is a string" do
      field = Marten::DB::Field::UUID.new("my_field")
      field.from_db("d764c9a6-439b-11eb-b378-0242ac130002").should eq UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")
    end

    it "returns a UUI object if the value is a UUID object" do
      field = Marten::DB::Field::UUID.new("my_field")
      field.from_db(UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")).should eq(
        UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")
      )
    end

    it "returns nil if the value is nil" do
      field = Marten::DB::Field::UUID.new("my_field")
      field.from_db(nil).should be_nil
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::UUID.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read a UUID string value from a DB result set" do
      field = Marten::DB::Field::UUID.new("my_field", db_column: "my_field_col")

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 'd764c9a6-439b-11eb-b378-0242ac130002'") do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should eq UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::UUID.new("my_field", db_column: "my_field_col")

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
      field = Marten::DB::Field::UUID.new("my_field", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::UUID
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      default_val = UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")
      field = Marten::DB::Field::UUID.new("my_field", default: default_val)
      column = field.to_column
      column.default.should eq default_val.hexstring
    end
  end

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::UUID.new("my_field")
      field.default.should be_nil
    end

    it "returns the configured default" do
      default_val = UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")
      field = Marten::DB::Field::UUID.new("my_field", default: default_val)
      field.default.should eq default_val
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::UUID.new("my_field")
      field.to_db(nil).should be_nil
    end

    it "returns a string value if the initial value is a UUID" do
      field = Marten::DB::Field::UUID.new("my_field")
      field.to_db(UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")).should eq "d764c9a6439b11ebb3780242ac130002"
    end

    it "returns a string value if the initial value is a UUID string" do
      field = Marten::DB::Field::UUID.new("my_field")
      field.to_db("d764c9a6-439b-11eb-b378-0242ac130002").should eq "d764c9a6439b11ebb3780242ac130002"
    end

    it "raises UnexpectedFieldValue if the initial value is a string that cannot be parsed as a UUID" do
      field = Marten::DB::Field::UUID.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db("bad value")
      end
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::UUID.new("my_field")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end

  describe "#validate" do
    it "adds an error to the record if the passed value is not a valid UUID" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::UUID.new("name")
      field.validate(obj, "foo")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "name"
      obj.errors.first.message.should eq "A valid UUID must be provided"
    end

    it "adds an error to the record if the passed value is not a UUID at all" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::UUID.new("name")
      field.validate(obj, [42])

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "name"
      obj.errors.first.message.should eq "A valid UUID must be provided"
    end

    it "does not add an error to the record if the passed value is nil" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::UUID.new("name")
      field.validate(obj, nil)

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the passed value is a valid UUID" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::UUID.new("name")
      field.validate(obj, UUID.new("d764c9a6-439b-11eb-b378-0242ac130002"))

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the passed value is a valid UUID string" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::UUID.new("name")
      field.validate(obj, "d764c9a6-439b-11eb-b378-0242ac130002")

      obj.errors.size.should eq 0
    end
  end
end
