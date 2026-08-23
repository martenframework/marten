require "./spec_helper"

describe Marten::Schema::Field::Decimal do
  describe "::new" do
    it "initializes a decimal field instance with the expected values" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.id.should eq "test_field"
      field.max_digits.should eq 10
      field.decimal_places.should eq 2
      field.required?.should be_true
    end

    it "raises if max_digits is not positive" do
      expect_raises(ArgumentError, "max_digits must be a positive integer") do
        Marten::Schema::Field::Decimal.new("test_field", max_digits: 0, decimal_places: 0)
      end
    end

    it "raises if decimal_places is greater than max_digits" do
      expect_raises(ArgumentError, "decimal_places must be less than or equal to max_digits") do
        Marten::Schema::Field::Decimal.new("test_field", max_digits: 2, decimal_places: 3)
      end
    end
  end

  describe "#deserialize" do
    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.deserialize(nil).should be_nil
    end

    it "returns nil if the passed value is an empty value" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.deserialize("").should be_nil
    end

    it "returns the decimal value corresponding to the passed string" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.deserialize("12231.12").should eq BigDecimal.new("12231.12")
    end

    it "returns the decimal value corresponding to the passed BigDecimal" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.deserialize(BigDecimal.new("19.99")).should eq BigDecimal.new("19.99")
    end

    it "returns the decimal value corresponding to the passed integer" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.deserialize(42).should eq BigDecimal.new("42")
    end

    it "returns the decimal value corresponding to the passed float" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.deserialize(19.99).should eq BigDecimal.new("19.99")
    end

    it "returns the decimal value corresponding to the passed JSON string" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.deserialize(JSON.parse(%{"12231.12"})).should eq BigDecimal.new("12231.12")
    end

    it "raises if the passed value has an unexpected type" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize(true) }
    end
  end

  describe "#serialize" do
    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.serialize(nil).should be_nil
    end

    it "returns the string version of the passed decimal number" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.serialize(BigDecimal.new("12593.451")).should eq "12593.451"
    end
  end

  describe "#max_digits" do
    it "returns the configured max digits" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.max_digits.should eq 10
    end
  end

  describe "#decimal_places" do
    it "returns the configured decimal places" do
      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.decimal_places.should eq 2
    end
  end

  describe "#perform_validation" do
    it "validates a value that fits the configured constraints" do
      schema = Marten::Schema::Field::DecimalSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["1932.12"]}
      )

      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not validate a value that is not a number" do
      schema = Marten::Schema::Field::DecimalSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["foo bar"]}
      )

      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 10, decimal_places: 2)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.decimal.errors.invalid")
    end

    it "does not validate a value that has too many decimal places" do
      schema = Marten::Schema::Field::DecimalSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["1.234"]}
      )

      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 5, decimal_places: 2)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t(
        "marten.schema.field.decimal.errors.max_decimal_places",
        decimal_places: 2
      )
    end

    it "does not validate a value that has too many digits in total" do
      schema = Marten::Schema::Field::DecimalSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["1234.56"]}
      )

      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 5, decimal_places: 2)
      field.perform_validation(schema)

      schema.errors.any? do |e|
        e.field == "test_field" &&
          e.message == I18n.t("marten.schema.field.decimal.errors.max_digits", max_digits: 5)
      end.should be_true
    end

    it "does not validate a value that has too many digits before the decimal point" do
      schema = Marten::Schema::Field::DecimalSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["1234"]}
      )

      field = Marten::Schema::Field::Decimal.new("test_field", max_digits: 5, decimal_places: 2)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t(
        "marten.schema.field.decimal.errors.max_whole_digits",
        max_whole_digits: 3
      )
    end
  end
end

module Marten::Schema::Field::DecimalSpec
  class TestSchema < Marten::Schema
    field :test_field, :decimal, max_digits: 10, decimal_places: 2
  end
end
