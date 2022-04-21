require "./spec_helper"

describe Marten::Schema::BoundField do
  describe "#errored?" do
    it "returns true if the field is errored" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("bar"))
      schema.valid?

      bound_field.errored?.should be_true
    end

    it "returns false if the field is not errored" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))
      schema.valid?

      bound_field.errored?.should be_false
    end
  end

  describe "#errors" do
    it "returns an array of the field errors" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("bar"))
      schema.valid?

      bound_field.errors.size.should eq 1
      bound_field.errors.first.field.should eq "bar"
      bound_field.errors.first.type.should eq "required"
    end

    it "returns an empty array if the field is not errored" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))
      schema.valid?

      bound_field.errors.should be_empty
    end
  end

  describe "#field" do
    it "returns the associated field definition" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))

      bound_field.field.should be_a Marten::Schema::Field::String
      bound_field.field.id.should eq "foo"
    end
  end

  describe "#id" do
    it "returns the field identifier" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))

      bound_field.id.should eq "foo"
    end
  end

  describe "#required?" do
    it "returns true if the field is required" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(
        schema,
        Marten::Schema::Field::String.new("test_field", required: true)
      )

      bound_field.required?.should be_true
    end

    it "returns false if the field is not required" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(
        schema,
        Marten::Schema::Field::String.new("test_field", required: false)
      )

      bound_field.required?.should be_false
    end
  end

  describe "#schema" do
    it "returns the associated schema" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))

      bound_field.schema.should eq schema
    end
  end

  describe "#value" do
    it "returns the field value if there is one" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))

      bound_field.value.should eq "hello"
    end

    it "fallbacks to the initial value if there is one" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        data: Marten::HTTP::Params::Data.new,
        initial: Marten::Schema::DataHash{"foo" => "hello"}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))

      bound_field.value.should eq "hello"
    end

    it "returns nil if there is no field value" do
      schema = Marten::Schema::BoundFieldSpec::TestSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["hello"]}
      )

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("bar"))

      bound_field.value.should be_nil
    end
  end
end

module Marten::Schema::BoundFieldSpec
  class TestSchema < Marten::Schema
    field :foo, :string
    field :bar, :string
  end
end
