require "./spec_helper"

describe Marten::Schema::Field::Enum do
  describe "#deserialize" do
    it "returns the string representation of the passed value" do
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"])
      field.deserialize(42).should eq "42"
      field.deserialize("foo bar").should eq "foo bar"
    end

    it "strips values automatically" do
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"])
      field.deserialize("  hello  ").should eq "hello"
    end

    it "returns the string representation of the passed JSON value" do
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"])
      field.deserialize(JSON.parse("42")).should eq "42"
      field.deserialize(JSON.parse(%{"foo bar"})).should eq "foo bar"
    end
  end

  describe "#perform_validation" do
    it "does not generate errors when the value matches one of the enum values" do
      schema = Marten::Schema::Field::EnumSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["green"]})
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"])

      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not generate errors when the value is nil and the field is not required" do
      schema = Marten::Schema::Field::EnumSpec::TestSchema.new(Marten::HTTP::Params::Data.new)
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"], required: false)

      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not generate errors when the value is a blank string and the field is not required" do
      schema = Marten::Schema::Field::EnumSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => [""]})
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"], required: false)

      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "generates an error when the value does not match one of the enum values" do
      schema = Marten::Schema::Field::EnumSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["bad"]})
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"])

      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.enum.errors.invalid", value: "bad")
    end
  end

  describe "#serialize" do
    it "returns the string representation of the passed value" do
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"])
      field.serialize(42).should eq "42"
      field.serialize("foo bar").should eq "foo bar"
    end

    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"])
      field.serialize(nil).should be_nil
    end
  end

  describe "#values" do
    it "returns the enum values" do
      field = Marten::Schema::Field::Enum.new("test_field", enum_values: ["red", "green", "blue"])
      field.values.should eq ["red", "green", "blue"]
    end
  end

  describe "::contribute_array_to_schema" do
    it "sets up the expected getter method allowing to fetch type-safe validated field data" do
      schema = Marten::Schema::Field::EnumSpec::WithArrayFields.new(
        Marten::HTTP::Params::Data{"colors" => ["red", "blue"]}
      )

      schema.colors.should be_nil
      expect_raises(NilAssertionError) { schema.colors! }
      schema.colors?.should be_false

      schema.valid?.should be_true

      schema.colors.should eq(
        [Marten::Schema::Field::EnumSpec::Color::RED, Marten::Schema::Field::EnumSpec::Color::BLUE]
      )
      schema.colors!.should eq(
        [Marten::Schema::Field::EnumSpec::Color::RED, Marten::Schema::Field::EnumSpec::Color::BLUE]
      )
      schema.colors?.should be_true
      typeof(schema.colors).should eq ::Array(Marten::Schema::Field::EnumSpec::Color)?
    end
  end

  describe "::contribute_to_schema" do
    it "creates a #raw_<field_id> method giving access to the raw field value" do
      schema = Marten::Schema::Field::EnumSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["green"]}
      )

      schema.raw_test_field.should be_nil

      schema.valid?.should be_true

      schema.raw_test_field.should eq "green"
    end

    it "creates a #raw_<field_id>! method giving access to the raw field value" do
      schema = Marten::Schema::Field::EnumSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["green"]}
      )

      expect_raises(NilAssertionError) { schema.raw_test_field! }

      schema.valid?.should be_true

      schema.raw_test_field!.should eq "green"
    end

    it "creates a #<field_id> method giving access to the actual enum value" do
      schema = Marten::Schema::Field::EnumSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["green"]}
      )

      schema.test_field.should be_nil

      schema.valid?.should be_true

      schema.test_field.should eq Marten::Schema::Field::EnumSpec::Color::GREEN
    end

    it "creates a #<field_id>! method giving access to the actual enum value" do
      schema = Marten::Schema::Field::EnumSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["green"]}
      )

      expect_raises(NilAssertionError) { schema.test_field! }

      schema.valid?.should be_true

      schema.test_field!.should eq Marten::Schema::Field::EnumSpec::Color::GREEN
    end

    it "creates a #<field_id>? method indicates whether the field has validated data" do
      schema = Marten::Schema::Field::EnumSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["green"]}
      )

      schema.test_field?.should be_false

      schema.valid?.should be_true

      schema.test_field?.should be_true
    end
  end
end

module Marten::Schema::Field::EnumSpec
  enum Color
    RED
    GREEN
    BLUE
  end

  class TestSchema < Marten::Schema
    field :test_field, :enum, values: Color
  end

  class WithArrayFields < Marten::Schema
    field :colors, :array, of: :enum, values: Color
  end
end
