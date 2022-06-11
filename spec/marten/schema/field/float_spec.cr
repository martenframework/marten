require "./spec_helper"

describe Marten::Schema::Field::Float do
  describe "#deserialize" do
    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.deserialize(nil).should be_nil
    end

    it "returns nil if the passed value is an empty value" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.deserialize(nil).should be_nil
      field.deserialize("").should be_nil
    end

    it "returns the float value corresponding to the passed string" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.deserialize("12231.12").should eq 12_231.12
    end

    it "returns the float value corresponding to the passed JSON string" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.deserialize(JSON.parse(%{"12231.12"})).should eq 12_231.12
    end

    it "returns the float value corresponding to the passed JSON int" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.deserialize(JSON.parse("12231")).should eq 12_231
    end

    it "returns the float value corresponding to the passed JSON float" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.deserialize(JSON.parse("12231.12")).should eq 12_231.12
    end

    it "raises if the passed value has an unexpected type" do
      field = Marten::Schema::Field::Float.new("test_field")
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize(true) }
    end
  end

  describe "#serialize" do
    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.serialize(nil).should be_nil
    end

    it "returns the string version of the passed float number" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.serialize(12_593.451).should eq "12593.451"
    end
  end

  describe "#max_value" do
    it "returns nil by default" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.max_value.should be_nil
    end

    it "returns the configured max value" do
      field = Marten::Schema::Field::Float.new("test_field", max_value: 1_434.35)
      field.max_value.should eq 1_434.35
    end
  end

  describe "#min_value" do
    it "returns nil by default" do
      field = Marten::Schema::Field::Float.new("test_field")
      field.min_value.should be_nil
    end

    it "returns the configured min value" do
      field = Marten::Schema::Field::Float.new("test_field", min_value: 10_233.12)
      field.min_value.should eq 10_233.12
    end
  end

  describe "#perform_validation" do
    it "validates a value if no min and max values are specified" do
      schema = Marten::Schema::Field::FloatSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["1932.12"]})

      field = Marten::Schema::Field::Float.new("test_field")
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "validates a value that is is greater than the allowed min value" do
      schema = Marten::Schema::Field::FloatSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["10.5"]})

      field = Marten::Schema::Field::Float.new("test_field", min_value: 9.5)
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not validate a value that is less than the allowed min value" do
      schema = Marten::Schema::Field::FloatSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["8.1"]})

      field = Marten::Schema::Field::Float.new("test_field", min_value: 9.5)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.float.errors.too_small", min_value: 9.5)
    end

    it "validates a value that is less than the allowed max value" do
      schema = Marten::Schema::Field::FloatSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["10.5"]})

      field = Marten::Schema::Field::Float.new("test_field", max_value: 11.3)
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not validate a value that is greater than the allowed max value" do
      schema = Marten::Schema::Field::FloatSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["12.5"]})

      field = Marten::Schema::Field::Float.new("test_field", max_value: 11.21)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.float.errors.too_big", max_value: 11.21)
    end

    it "does not validate a value that is not a number" do
      schema = Marten::Schema::Field::FloatSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["foo bar"]})

      field = Marten::Schema::Field::Float.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.float.errors.invalid")
    end

    it "does not validate a value that is not finite" do
      schema = Marten::Schema::Field::FloatSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["NaN"]})

      field = Marten::Schema::Field::Float.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.float.errors.invalid")
    end
  end
end

module Marten::Schema::Field::FloatSpec
  class TestSchema < Marten::Schema
    field :test_field, :float
  end
end
