require "./spec_helper"

describe Marten::Schema do
  describe "::get_field" do
    it "returns the field associated with an identifier string" do
      field = Marten::SchemaSpec::SimpleSchema.get_field("foo")
      field.should be_a Marten::Schema::Field::String
      field.id.should eq "foo"
    end

    it "returns the field associated with an identifier symbol" do
      field = Marten::SchemaSpec::SimpleSchema.get_field(:foo)
      field.should be_a Marten::Schema::Field::String
      field.id.should eq "foo"
    end

    it "raises if the field cannot be found" do
      expect_raises(Marten::Schema::Errors::UnknownField) do
        Marten::SchemaSpec::SimpleSchema.get_field(:unknown)
      end
    end
  end

  describe "::fields" do
    it "returns the specified fields" do
      Marten::SchemaSpec::SimpleSchema.fields.size.should eq 2
      Marten::SchemaSpec::SimpleSchema.fields.map(&.id).should eq ["foo", "bar"]
    end
  end

  describe "#get_field_value" do
    it "returns the raw value associated with a given field identifier string" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      schema.get_field_value("foo").should eq "hello"
    end

    it "returns the raw value associated with a given field identifier symbol" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      schema.get_field_value(:foo).should eq "hello"
    end

    it "returns nil no value is associated with a given field identifier" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      schema.get_field_value(:bar).should be_nil
    end

    it "raises if the field cannot be found" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      expect_raises(Marten::Schema::Errors::UnknownField) { schema.get_field_value("unknown") }
    end
  end
end

module Marten::SchemaSpec
  class SimpleSchema < Marten::Schema
    field :foo, :string
    field :bar, :string
  end
end
