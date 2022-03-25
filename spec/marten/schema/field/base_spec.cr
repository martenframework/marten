require "./spec_helper"

describe Marten::Schema::Field::Base do
  describe "#id" do
    it "returns the field identifier" do
      field = Marten::Schema::Field::BaseSpec::TestField.new("test_field")
      field.id.should eq "test_field"
    end
  end

  describe "#perform_validation" do
    it "returns the deserialized value" do
      schema = Marten::Schema::Field::BaseSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["  hello  "]}
      )
      field = Marten::Schema::Field::BaseSpec::TestField.new("test_field")
      field.perform_validation(schema).should eq "hello"
    end

    it "adds an error to the schema object if the serialization fails with an argument error" do
      schema = Marten::Schema::Field::BaseSpec::TestSchema.new(
        Marten::HTTP::Params::Data.new
      )

      field = Marten::Schema::Field::BaseSpec::TestFieldWithFailingDeserialization.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.type.should eq "invalid"
    end

    it "adds an error to the schema object if the field is required and the value is nil" do
      schema = Marten::Schema::Field::BaseSpec::TestSchema.new(
        Marten::HTTP::Params::Data.new
      )

      field = Marten::Schema::Field::BaseSpec::TestField.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.type.should eq "required"
    end

    it "adds an error to the schema object if the field is required and the value is blank" do
      schema = Marten::Schema::Field::BaseSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => [""]})

      field = Marten::Schema::Field::BaseSpec::TestField.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.type.should eq "required"
    end
  end

  describe "#required?" do
    it "returns true if the field is required" do
      field = Marten::Schema::Field::BaseSpec::TestField.new("test_field", required: true)
      field.required?.should be_true
    end

    it "returns false if the field is not required" do
      field = Marten::Schema::Field::BaseSpec::TestField.new("test_field", required: false)
      field.required?.should be_false
    end
  end
end

module Marten::Schema::Field::BaseSpec
  class TestSchema < Marten::Schema
    field :test_field, :string
  end

  class TestField < Marten::Schema::Field::Base
    def deserialize(value) : ::String?
      value.to_s.strip
    end

    def serialize(value) : ::String?
      value.to_s
    end
  end

  class TestFieldWithFailingDeserialization < Marten::Schema::Field::Base
    def deserialize(value) : ::String?
      raise ArgumentError.new("This is bad")
    end

    def serialize(value) : ::String?
      value.to_s
    end
  end
end