require "./spec_helper"

describe Marten::DB::Field::Base do
  describe "::new" do
    it "initializes a field instance with the expected defaults" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field")
      field.id.should eq "my_field"
      field.primary_key?.should be_false
      field.blank?.should be_false
      field.null?.should be_false
      field.unique?.should be_false
      field.editable?.should be_true
      field.db_column.should eq field.id
      field.db_index?.should be_false
    end
  end

  describe "#id" do
    it "returns the field ID" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field")
      field.id.should eq "my_field"
    end
  end

  describe "#blank?" do
    it "returns false if the field is not allowed to be blank" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", blank: false)
      field.blank?.should be_false
    end

    it "returns true if the field is allowed to be blank" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", blank: true)
      field.blank?.should be_true
    end
  end

  describe "#db_column" do
    it "returns the field ID if no column name is explicitly specified" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field")
      field.db_column.should eq "my_field"
    end

    it "returns the column name if explicitly specified" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", db_column: "my_field_id")
      field.db_column.should eq "my_field_id"
    end
  end

  describe "#db_index?" do
    it "returns true if the field is indexed" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", db_index: true)
      field.db_index?.should be_true
    end

    it "returns false if the field is not indexed" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", db_index: false)
      field.db_index?.should be_false
    end
  end

  describe "#editable?" do
    it "returns true if the field is editable" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", editable: true)
      field.editable?.should be_true
    end

    it "returns false if the field is not editable" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", editable: false)
      field.editable?.should be_false
    end
  end

  describe "#null?" do
    it "returns true if the field is nullable" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", null: true)
      field.null?.should be_true
    end

    it "returns false if the field is not nullable" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", null: false)
      field.null?.should be_false
    end
  end

  describe "#prepare_save" do
    it "does nothing by default" do
      obj = Tag.create!(name: "crystal", is_active: true)
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field")
      field.prepare_save(obj, new_record: false).should be_nil
    end
  end

  describe "#primary_key?" do
    it "returns true if the field is a primary" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", primary_key: true)
      field.primary_key?.should be_true
    end

    it "returns false if the field is not a primary key" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", primary_key: false)
      field.primary_key?.should be_false
    end
  end

  describe "#unique?" do
    it "returns true if the field has a unicity constraint" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", unique: true)
      field.unique?.should be_true
    end

    it "returns false if the field does not have a unicity constraint" do
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field", unique: false)
      field.unique?.should be_false
    end
  end

  describe "#validate" do
    it "does nothing by default" do
      obj = Tag.create!(name: "crystal", is_active: true)
      field = Marten::DB::Field::BaseSpec::TestField.new("my_field")
      field.validate(obj, 42).should be_nil
    end
  end

  describe "::contribute_to_model" do
    it "properly registers a field on a specific model" do
      field = Tag.get_field("name")
      field.should be_a Marten::DB::Field::String
    end

    it "properly generates a getter method for the field on the model class" do
      obj_1 = Tag.create!(name: "crystal", is_active: true)
      obj_1.name.should eq "crystal"

      obj_2 = Tag.new
      obj_2.name.should be_nil
    end

    it "properly generates a nil-safe getter method for the field on the model class" do
      obj_1 = Tag.create!(name: "crystal", is_active: true)
      obj_1.name!.should eq "crystal"

      obj_2 = Tag.new
      expect_raises(NilAssertionError) { obj_2.name! }
    end

    it "properly generates a setter method for the field on the model class" do
      obj = Tag.create!(name: "crystal", is_active: true)

      obj.name = "ruby"
      obj.name.should eq "ruby"

      obj.name = nil
      obj.name.should be_nil
    end
  end

  describe "#perform_validation" do
    it "adds an error to the record if the field is not nullable and the value is nil" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: false, max_size: 128)
      field.perform_validation(obj)

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "name"
      obj.errors.first.type.should eq "null"
    end

    it "does not add an error to the record if the field is not nullable and not editable and the value is nil" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: false, editable: false, max_size: 128)
      field.perform_validation(obj)

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the field is nullable and the value is nil" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::String.new("name", null: true, blank: true, max_size: 128)
      field.perform_validation(obj)

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the field is not nullable and the value is not nil" do
      obj = Tag.new(name: "crystal")

      field = Marten::DB::Field::String.new("name", null: true, max_size: 128)
      field.perform_validation(obj)

      obj.errors.size.should eq 0
    end

    it "adds an error to the record if the field cannot be blank and the value is blank" do
      obj = Tag.new(name: "")

      field = Marten::DB::Field::String.new("name", blank: false, max_size: 128)
      field.perform_validation(obj)

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "name"
      obj.errors.first.type.should eq "blank"
    end

    it "does not add an error to the record if the field cannot be blank and is not editable and the value is blank" do
      obj = Tag.new(name: "")

      field = Marten::DB::Field::String.new("name", blank: false, editable: false, max_size: 128)
      field.perform_validation(obj)

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the field can be blank and the value is blank" do
      obj = Tag.new(name: "")

      field = Marten::DB::Field::String.new("name", blank: true, max_size: 128)
      field.perform_validation(obj)

      obj.errors.size.should eq 0
    end

    it "does not add an error to the record if the field cannot be blank and the value is not blank" do
      obj = Tag.new(name: "crystal")

      field = Marten::DB::Field::String.new("name", blank: false, max_size: 128)
      field.perform_validation(obj)

      obj.errors.size.should eq 0
    end
  end
end

module Marten::DB::Field::BaseSpec
  class TestField < Marten::DB::Field::Base
    def from_db_result_set(result_set : ::DB::ResultSet) : Int64?
      result_set.read(Int32 | Int64 | Nil).try(&.to_i64)
    end

    def to_column : Management::Column::Base
      Marten::DB::Management::Column::BigInt.new(
        db_column,
        primary_key?,
        null?,
        unique?,
        db_index?
      )
    end

    def to_db(value) : ::DB::Any
      case value
      when Nil
        nil
      when Int64
        value
      when Int8, Int16, Int32
        value.as(Int8 | Int16 | Int32).to_i64
      else
        raise_unexpected_field_value(value)
      end
    end
  end
end
