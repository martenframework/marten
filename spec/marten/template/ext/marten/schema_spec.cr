require "./spec_helper"

describe Marten::Schema do
  describe "#resolve_template_attribute" do
    it "can return a specific bound field" do
      schema = Marten::SchemaExtSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      bound_field = schema.resolve_template_attribute("foo")
      bound_field.should eq schema["foo"]
    end

    it "can return the error set" do
      schema = Marten::SchemaExtSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      schema.valid?

      errors = schema.resolve_template_attribute("errors")
      errors.should eq schema.errors
    end

    it "returns nil if the passed attribute name is not found" do
      schema = Marten::SchemaExtSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      schema.resolve_template_attribute("unknown").should be_nil
    end
  end
end

module Marten::SchemaExtSpec
  class SimpleSchema < Marten::Schema
    field :foo, :string
  end
end
