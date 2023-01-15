require "./spec_helper"

describe Marten::Schema::Field::Email do
  describe "#max_size" do
    it "returns 254 by default" do
      field = Marten::Schema::Field::Email.new("test_field")
      field.max_size.should eq 254
    end
  end

  describe "#perform_validation" do
    it "adds an error to the schema if the string size is greater than the allowed limit" do
      schema = Marten::Schema::Field::EmailSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["a" * 255]}
      )

      field = Marten::Schema::Field::Email.new("test_field")
      field.perform_validation(schema)

      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.string.errors.too_long", max_size: 254)
    end

    it "adds an error to the schema if the string does not correspond to a valid email" do
      schema = Marten::Schema::Field::EmailSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["this is not an email"]}
      )

      field = Marten::Schema::Field::Email.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.email.errors.invalid")
    end

    it "does not add an error to the schema if the string contains a valid email" do
      schema = Marten::Schema::Field::EmailSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["test@example.com"]}
      )

      field = Marten::Schema::Field::Email.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 0
    end

    it "does not add an invalid email error if the field value is empty" do
      schema = Marten::Schema::Field::EmailSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => [""]}
      )

      field = Marten::Schema::Field::Email.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.type.should eq "required"
    end
  end
end

module Marten::Schema::Field::EmailSpec
  class TestSchema < Marten::Schema
    field :test_field, :email
  end
end
