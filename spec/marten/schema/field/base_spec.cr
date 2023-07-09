require "./spec_helper"

describe Marten::Schema::Field::Base do
  describe "#empty_value?" do
    it "returns true for nil values" do
      field = Marten::Schema::Field::BaseSpec::TestField.new("test_field")

      field.empty_value?(nil).should be_true
    end

    it "returns true for blank strings" do
      field = Marten::Schema::Field::BaseSpec::TestField.new("test_field")

      field.empty_value?("").should be_true
    end

    it "returns false for other values" do
      field = Marten::Schema::Field::BaseSpec::TestField.new("test_field")

      field.empty_value?(42).should be_false
      field.empty_value?("foo").should be_false
    end
  end

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

  describe "::contribute_to_schema" do
    it "sets up the expected getter method allowing to fetch type-safe validated field data" do
      schema = Marten::Schema::Field::BaseSpec::FooBarSchema.new(
        Marten::Schema::DataHash{"foo" => "", "bar" => "42"}
      )

      schema.foo.should be_nil
      expect_raises(NilAssertionError) { schema.foo! }
      schema.foo?.should be_false

      schema.bar.should be_nil
      schema.bar?.should be_false
      expect_raises(NilAssertionError) { schema.bar! }

      schema.valid?.should be_true

      schema.foo.should eq ""
      schema.foo!.should eq ""
      schema.foo?.should be_false
      typeof(schema.foo).should eq String?

      schema.bar.should eq 42
      schema.bar!.should eq 42
      schema.bar?.should be_true
      typeof(schema.bar).should eq Int64?
    end
  end
end

module Marten::Schema::Field::BaseSpec
  class TestSchema < Marten::Schema
    field :test_field, :string
  end

  class FooBarSchema < Marten::Schema
    field :foo, :string, required: false
    field :bar, :int
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
