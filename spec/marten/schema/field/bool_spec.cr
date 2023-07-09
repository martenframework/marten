require "./spec_helper"

describe Marten::Schema::Field::Bool do
  describe "#empty_value?" do
    it "returns true for falsey values" do
      field = Marten::Schema::Field::Bool.new("test_field")

      field.empty_value?(nil).should be_true
      field.empty_value?(false).should be_true
    end

    it "returns false for truthy values" do
      field = Marten::Schema::Field::Bool.new("test_field")

      field.empty_value?(true).should be_false
      field.empty_value?("foo").should be_false
    end
  end

  describe "#deserialize" do
    it "returns true if the value is true" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.deserialize(true).should be_true
    end

    it "returns true if the value equals \"true\"" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.deserialize("true").should be_true
    end

    it "returns true if the value equals 1" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.deserialize(1).should be_true
    end

    it "returns true if the value equals \"1\"" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.deserialize("1").should be_true
    end

    it "returns true if the value equals \"yes\"" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.deserialize("yes").should be_true
    end

    it "returns true if the value equals \"on\"" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.deserialize("on").should be_true
    end

    it "returns true if the value is a truthy JSON value" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.deserialize(JSON.parse("true")).should be_true
      field.deserialize(JSON.parse(%{"true"})).should be_true
      field.deserialize(JSON.parse(%{1})).should be_true
      field.deserialize(JSON.parse(%{"1"})).should be_true
    end

    it "returns false in all other instances" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.deserialize("").should be_false
      field.deserialize("false").should be_false
    end

    it "returns false if the value is a falsy JSON value" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.deserialize(JSON.parse("false")).should be_false
      field.deserialize(JSON.parse(%{"false"})).should be_false
      field.deserialize(JSON.parse(%{0})).should be_false
      field.deserialize(JSON.parse(%{"0"})).should be_false
    end
  end

  describe "#serialize" do
    it "returns the string version of the passed value" do
      field = Marten::Schema::Field::Bool.new("test_field")
      field.serialize(true).should eq "true"
      field.serialize(false).should eq "false"
    end
  end

  describe "#perform_validation" do
    it "adds an error to the schema object if the field is required and the deserialized value is false" do
      schema = Marten::Schema::Field::BoolSpec::TestSchema.new(
        Marten::HTTP::Params::Data.new
      )

      field = Marten::Schema::Field::Bool.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.type.should eq "required"
    end
  end
end

module Marten::Schema::Field::BoolSpec
  class TestSchema < Marten::Schema
    field :test_field, :bool
  end
end
