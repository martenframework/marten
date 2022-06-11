require "./spec_helper"

describe Marten::Schema::Field::Int do
  describe "#deserialize" do
    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::Int.new("test_field")
      field.deserialize(nil).should be_nil
    end

    it "returns nil if the passed value is an empty value" do
      field = Marten::Schema::Field::Int.new("test_field")
      field.deserialize(nil).should be_nil
      field.deserialize("").should be_nil
    end

    it "returns the integer value corresponding to the passed string" do
      field = Marten::Schema::Field::Int.new("test_field")
      field.deserialize("1223112").should eq 1_223_112
    end

    it "returns the integer value corresponding to the passed JSON string" do
      field = Marten::Schema::Field::Int.new("test_field")
      field.deserialize(JSON.parse(%{"1223112"})).should eq 1_223_112
    end

    it "returns the integer value corresponding to the passed JSON integer" do
      field = Marten::Schema::Field::Int.new("test_field")
      field.deserialize(JSON.parse("1223112")).should eq 1_223_112
    end

    it "raises if the passed value has an unexpected type" do
      field = Marten::Schema::Field::Int.new("test_field")
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize(true) }
    end
  end

  describe "#serialize" do
    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::Int.new("test_field")
      field.serialize(nil).should be_nil
    end

    it "returns the string version of the passed integer" do
      field = Marten::Schema::Field::Int.new("test_field")
      field.serialize(12_593).should eq "12593"
    end
  end

  describe "#max_value" do
    it "returns nil by default" do
      field = Marten::Schema::Field::Int.new("test_field")
      field.max_value.should be_nil
    end

    it "returns the configured max value" do
      field = Marten::Schema::Field::Int.new("test_field", max_value: 1_434)
      field.max_value.should eq 1_434
    end
  end

  describe "#min_size" do
    it "returns nil by default" do
      field = Marten::Schema::Field::Int.new("test_field")
      field.min_value.should be_nil
    end

    it "returns the configured min value" do
      field = Marten::Schema::Field::Int.new("test_field", min_value: 10_233)
      field.min_value.should eq 10_233
    end
  end

  describe "#perform_validation" do
    it "validates a value if no min and max values are specified" do
      schema = Marten::Schema::Field::IntSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["1932"]})

      field = Marten::Schema::Field::Int.new("test_field")
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "validates a value that is is greater than the allowed min value" do
      schema = Marten::Schema::Field::IntSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["10"]})

      field = Marten::Schema::Field::Int.new("test_field", min_value: 9)
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not validate a value that is less than the allowed min value" do
      schema = Marten::Schema::Field::IntSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["8"]})

      field = Marten::Schema::Field::Int.new("test_field", min_value: 9)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.int.errors.too_small", min_value: 9)
    end

    it "validates a value that is less than the allowed max value" do
      schema = Marten::Schema::Field::IntSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["10"]})

      field = Marten::Schema::Field::Int.new("test_field", max_value: 11)
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not validate a value that is greater than the allowed max value" do
      schema = Marten::Schema::Field::IntSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["12"]})

      field = Marten::Schema::Field::Int.new("test_field", max_value: 11)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.int.errors.too_big", max_value: 11)
    end

    it "does not validate a value that is not a number" do
      schema = Marten::Schema::Field::IntSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["foo bar"]})

      field = Marten::Schema::Field::Int.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.int.errors.invalid")
    end
  end
end

module Marten::Schema::Field::IntSpec
  class TestSchema < Marten::Schema
    field :test_field, :int
  end
end
