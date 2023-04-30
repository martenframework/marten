require "./spec_helper"

describe Marten::Schema::Field::Duration do
  describe "#deserialize" do
    it "returns nil if the value is nil" do
      field = Marten::Schema::Field::Duration.new("test_field")
      field.deserialize(nil).should be_nil
    end

    it "returns nil if the passed value is an empty value" do
      field = Marten::Schema::Field::Duration.new("test_field")
      field.deserialize("").should be_nil
    end

    it "returns a time span object if the value is a time span object" do
      field = Marten::Schema::Field::Duration.new("test_field")
      field.deserialize(2.hours).should eq 2.hours
    end

    it "returns the expected time span object if the value is a string properly formatted" do
      test_cases = [
        ["12.01:15:20.002200000", Time::Span.new(days: 12, hours: 1, minutes: 15, seconds: 20, nanoseconds: 2200000)],
        ["02:15:20.002200000", Time::Span.new(hours: 2, minutes: 15, seconds: 20, nanoseconds: 2200000)],
        ["03:01:00", Time::Span.new(hours: 3, minutes: 1)],
      ]

      test_cases.each do |test_case|
        field = Marten::Schema::Field::Duration.new("test_field")
        field.deserialize(test_case[0]).should eq test_case[1]
      end
    end

    it "returns the expected time span object if the value is a string properly formatted using ISO 8601" do
      test_cases = [
        ["P4DT1H15M20S", Time::Span.new(days: 4, hours: 1, minutes: 15, seconds: 20)],
        ["P3DT12H", Time::Span.new(days: 3, hours: 12)],
        ["PT1M", Time::Span.new(minutes: 1)],
        ["PT15H33M44S", Time::Span.new(hours: 15, minutes: 33, seconds: 44)],
        ["-P3DT1H", Time::Span.new(days: -3, hours: -1)],
        ["P4D", Time::Span.new(days: 4)],
        ["-P1D", Time::Span.new(days: -1)],
        ["PT5H", Time::Span.new(hours: 5)],
        ["-PT5H", Time::Span.new(hours: -5)],
        ["PT5M", Time::Span.new(minutes: 5)],
        ["-PT5M", Time::Span.new(minutes: -5)],
        ["PT5S", Time::Span.new(seconds: 5)],
        ["-PT5S", Time::Span.new(seconds: -5)],
        ["PT0.000000005S", Time::Span.new(nanoseconds: 5)],
        ["PT0,000000005S", Time::Span.new(nanoseconds: 5)],
        ["-PT0.000000005S", Time::Span.new(nanoseconds: -5)],
        ["-PT0,000000005S", Time::Span.new(nanoseconds: -5)],
        ["-P4DT1H", Time::Span.new(days: -4, hours: -1)],
      ]

      test_cases.each do |test_case|
        field = Marten::Schema::Field::Duration.new("test_field")
        field.deserialize(test_case[0]).should eq test_case[1]
      end
    end

    it "raises if the passed value is a string that can't be parsed properly" do
      field = Marten::Schema::Field::Duration.new("test_field")
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize("this is bad") }
    end

    it "raises if the passed value has an unexpected type" do
      field = Marten::Schema::Field::Duration.new("test_field")
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize(true) }
    end
  end

  describe "#serialize" do
    it "returns the string version of the passed value" do
      field = Marten::Schema::Field::Duration.new("test_field")
      field.serialize(2.hours).should eq "02:00:00"
    end

    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::Duration.new("test_field")
      field.serialize(nil).should be_nil
    end
  end

  describe "#perform_validation" do
    it "validates a value that is in the standard time span format" do
      [
        "12.01:15:20.002200000",
        "02:15:20.002200000",
        "03:01:00",
      ].each do |raw_value|
        schema = Marten::Schema::Field::DurationSpec::TestSchema.new(
          Marten::HTTP::Params::Data{"test_field" => [raw_value]}
        )

        field = Marten::Schema::Field::Duration.new("test_field")
        field.perform_validation(schema)

        schema.errors.should be_empty
      end
    end

    it "validates a value that is in the ISO 8601 format" do
      [
        "P4DT1H15M20S",
        "P3DT12H",
        "PT1M",
        "PT15H33M44S",
      ].each do |raw_value|
        schema = Marten::Schema::Field::DurationSpec::TestSchema.new(
          Marten::HTTP::Params::Data{"test_field" => [raw_value]}
        )

        field = Marten::Schema::Field::Duration.new("test_field")
        field.perform_validation(schema)

        schema.errors.should be_empty
      end
    end

    it "does not validate a value that is not a duration" do
      schema = Marten::Schema::Field::DurationSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["this is bad"]}
      )

      field = Marten::Schema::Field::Duration.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.duration.errors.invalid")
    end
  end
end

module Marten::Schema::Field::DurationSpec
  class TestSchema < Marten::Schema
    field :test_field, :duration
  end
end
