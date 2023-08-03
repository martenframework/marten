require "./spec_helper"

describe Marten::Schema::Field::Slug do
  describe "#max_size" do
    it "returns 50 by default" do
      field = Marten::Schema::Field::Slug.new("test_field")
      field.max_size.should eq 50
    end
  end

  describe "#perform_validation" do
    it "adds an error to the record if the string contains two consecutive dashes" do
      schema = Marten::Schema::Field::SlugSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["th1s-1s-not--val1d-slug"]}
      )

      field = Marten::Schema::Field::Slug.new("test_field")
      field.perform_validation(schema)

      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.slug.errors.invalid")
    end

    it "adds an error to the record if the string starts with a non alphanumeric character" do
      schema = Marten::Schema::Field::SlugSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["-foo"]}
      )

      field = Marten::Schema::Field::Slug.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.slug.errors.invalid")
    end

    it "adds an error to the record if the string ends with a non alphanumeric character" do
      schema = Marten::Schema::Field::SlugSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["foo-"]}
      )

      field = Marten::Schema::Field::Slug.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.slug.errors.invalid")
    end

    it "adds an error to the record if the string contains non-ascii characters" do
      schema = Marten::Schema::Field::SlugSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["foo-✓-bar"]}
      )

      field = Marten::Schema::Field::Slug.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "test_field"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.slug.errors.invalid")
    end

    it "does not add an error to the schema if the string contains a valid slug" do
      schema = Marten::Schema::Field::SlugSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"test_field" => ["th1s-1s-val1d-slug"]}
      )

      field = Marten::Schema::Field::Slug.new("test_field")
      field.perform_validation(schema)

      schema.errors.size.should eq 0
    end
  end
end

module Marten::Schema::Field::SlugSpec
  class TestSchema < Marten::Schema
    field :test_field, :slug
  end
end
