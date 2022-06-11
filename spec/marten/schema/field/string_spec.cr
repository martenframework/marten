require "./spec_helper"

describe Marten::Schema::Field::String do
  describe "#deserialize" do
    it "returns the string representation of the passed value" do
      field = Marten::Schema::Field::String.new("test_field")
      field.deserialize(42).should eq "42"
      field.deserialize("foo bar").should eq "foo bar"
    end

    it "strips values if configured to strip values" do
      field = Marten::Schema::Field::String.new("test_field", strip: true)
      field.deserialize("  hello  ").should eq "hello"
    end

    it "does not strip values if configured to not strip values" do
      field = Marten::Schema::Field::String.new("test_field", strip: false)
      field.deserialize("  hello  ").should eq "  hello  "
    end

    it "returns the string representation of the passed JSON value" do
      field = Marten::Schema::Field::String.new("test_field")
      field.deserialize(JSON.parse("42")).should eq "42"
      field.deserialize(JSON.parse(%{"foo bar"})).should eq "foo bar"
    end
  end

  describe "#max_size" do
    it "returns nil by default" do
      field = Marten::Schema::Field::String.new("test_field")
      field.max_size.should be_nil
    end

    it "returns the configured max size" do
      field = Marten::Schema::Field::String.new("test_field", max_size: 128)
      field.max_size.should eq 128
    end
  end

  describe "#min_size" do
    it "returns nil by default" do
      field = Marten::Schema::Field::String.new("test_field")
      field.min_size.should be_nil
    end

    it "returns the configured max size" do
      field = Marten::Schema::Field::String.new("test_field", min_size: 3)
      field.min_size.should eq 3
    end
  end

  describe "#serialize" do
    it "returns the string representation of the passed value" do
      field = Marten::Schema::Field::String.new("test_field")
      field.serialize(42).should eq "42"
      field.serialize("foo bar").should eq "foo bar"
    end

    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::String.new("test_field")
      field.serialize(nil).should be_nil
    end
  end

  describe "#strip?" do
    it "returns true by default" do
      field = Marten::Schema::Field::String.new("test_field")
      field.strip?.should be_true
    end

    it "returns true if explicitly configured to strip values" do
      field = Marten::Schema::Field::String.new("test_field", strip: true)
      field.strip?.should be_true
    end

    it "returns false if explicitly configured to not strip values" do
      field = Marten::Schema::Field::String.new("test_field", strip: false)
      field.strip?.should be_false
    end
  end

  describe "#perform_validation" do
    it "validates a value if no min and max sizes are specified" do
      schema = Marten::Schema::Field::StringSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["hello"]})

      field = Marten::Schema::Field::String.new("test_field")
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "validates a value whose size is greater than the allowed min size" do
      schema = Marten::Schema::Field::StringSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["hello"]})

      field = Marten::Schema::Field::String.new("test_field", min_size: 3)
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not validate a value whose size is less than the allowed min size" do
      schema = Marten::Schema::Field::StringSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["ab"]})

      field = Marten::Schema::Field::String.new("test_field", min_size: 3)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.string.errors.too_short", min_size: 3)
    end

    it "validates a value whose size is less than the allowed max size" do
      schema = Marten::Schema::Field::StringSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["hello"]})

      field = Marten::Schema::Field::String.new("test_field", max_size: 10)
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not validate a value that whose size is less than the allowed min size" do
      schema = Marten::Schema::Field::StringSpec::TestSchema.new(Marten::HTTP::Params::Data{"test_field" => ["foo"]})

      field = Marten::Schema::Field::String.new("test_field", max_size: 2)
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.string.errors.too_long", max_size: 2)
    end
  end
end

module Marten::Schema::Field::StringSpec
  class TestSchema < Marten::Schema
    field :test_field, :string
  end
end
