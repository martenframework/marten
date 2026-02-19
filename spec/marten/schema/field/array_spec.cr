require "./spec_helper"

describe Marten::Schema::Field::Array do
  describe "#empty_value?" do
    it "returns true if the value is nil" do
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field.empty_value?(nil).should be_true
    end

    it "returns true if the value is an empty array" do
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field.empty_value?([] of String).should be_true
    end

    it "returns false if the value is an array with at least one element" do
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field.empty_value?(["hello"]).should be_false
    end
  end

  describe "#deserialize" do
    it "returns an array of the deserialized values" do
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field.deserialize(["hello", "world"]).should eq ["hello", "world"]
    end

    it "returns nil if the value is nil" do
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field.deserialize(nil).should be_nil
    end

    it "returns an empty array if the value is an empty array" do
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field.deserialize(42).should be_nil
    end
  end

  describe "#get_raw_data" do
    it "returns the expected raw data based on the provided HTTP data object" do
      schema = Marten::Schema::Field::ArraySpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["hello", "world"]}
      )

      field_1 = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field_1.get_raw_data(schema.data).should eq ["hello", "world"]

      field_2 = Marten::Schema::Field::Array.new("other_field", Marten::Schema::Field::String.new("other_field"))
      field_2.get_raw_data(schema.data).should be_nil
    end

    it "returns the expected raw data based on the provided data hash object" do
      schema = Marten::Schema::Field::ArraySpec::TestSchema.new(
        Marten::Schema::DataHash{"test_field" => ["hello", "world"], "other_field" => "foo"}
      )

      field_1 = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field_1.get_raw_data(schema.data).should eq ["hello", "world"]

      field_2 = Marten::Schema::Field::Array.new("other_field", Marten::Schema::Field::String.new("other_field"))
      field_2.get_raw_data(schema.data).should eq ["foo"]
    end

    it "returns the expected raw data if the values were extracted from a parsed JSON" do
      raw_data = %{{ "test_field": ["hello", "world"], "other_field": "foo" }}
      raw_data_hash = Marten::HTTP::Params::Data::RawHash.new

      if !(json_params = JSON.parse(raw_data).as_h?).nil?
        json_params.each do |key, value|
          raw_data_hash[key] = [] of Marten::HTTP::Params::Data::Value unless raw_data_hash.has_key?(key)
          raw_data_hash[key].as(Marten::HTTP::Params::Data::Values) << value
        end
      end

      data = Marten::HTTP::Params::Data.new(raw_data_hash)

      schema = Marten::Schema::Field::ArraySpec::TestSchema.new(data)
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))

      field.get_raw_data(schema.data).should eq ["hello", "world"]

      schema.valid?.should be_true

      schema.test_field.should eq ["hello", "world"]
    end
  end

  describe "#serialize" do
    it "returns the serialized values" do
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field.serialize(["hello", "world"]).should eq ["hello", "world"]
    end

    it "returns nil if the value is nil" do
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field.serialize(nil).should be_nil
    end

    it "returns nil if the value is not an array" do
      field = Marten::Schema::Field::Array.new("test_field", Marten::Schema::Field::String.new("test_field"))
      field.serialize(42).should be_nil
    end
  end

  describe "#validate" do
    it "validates the array values according to the provided field definition" do
      schema_1 = Marten::Schema::Field::ArraySpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["hello", "world", "too_long"]}
      )
      schema_2 = Marten::Schema::Field::ArraySpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["hello", "world"]}
      )

      field = Marten::Schema::Field::Array.new(
        "test_field",
        Marten::Schema::Field::String.new("test_field", max_size: 5)
      )

      field.perform_validation(schema_1)
      schema_1.errors.size.should eq 1
      schema_1.errors.first.field.should eq "test_field"
      schema_1.errors.first.message.should eq I18n.t("marten.schema.field.string.errors.too_long", max_size: 5)

      field.perform_validation(schema_2)
      schema_2.errors.should be_empty
    end
  end

  describe "::contribute_to_schema" do
    it "sets up the expected getter method allowing to fetch type-safe validated field data" do
      schema = Marten::Schema::Field::ArraySpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["red", "blue"]}
      )

      schema.test_field.should be_nil
      expect_raises(NilAssertionError) { schema.test_field! }
      schema.test_field?.should be_false

      schema.other_field.should be_nil
      expect_raises(NilAssertionError) { schema.other_field! }
      schema.other_field?.should be_false

      schema.valid?.should be_true

      schema.test_field.should eq ["red", "blue"]
      schema.test_field!.should eq ["red", "blue"]
      schema.test_field?.should be_true
      typeof(schema.test_field).should eq ::Array(String?)?

      schema.other_field.should be_nil
      expect_raises(NilAssertionError) { schema.other_field! }
      schema.other_field?.should be_false
      typeof(schema.other_field).should eq ::Array(String?)?
    end
  end
end

module Marten::Schema::Field::ArraySpec
  class TestSchema < Marten::Schema
    field :test_field, :array, of: :string
    field :other_field, :array, of: :string, required: false
    field :again_another_field, :array, of: :string, required: false, max_size: 5
  end
end
