require "./spec_helper"

describe Marten::Schema::BoundField do
  describe "#resolve_template_attribute" do
    it "is able to return the id of the field" do
      schema = Marten::Schema::BoundFieldExtSpec::TestSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))

      bound_field.resolve_template_attribute("id").should eq "foo"
    end

    it "is able to return the result of #errored?" do
      schema = Marten::Schema::BoundFieldExtSpec::TestSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      schema.valid?

      bound_field_1 = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))
      bound_field_1.resolve_template_attribute("errored?").should be_false

      bound_field_2 = Marten::Schema::BoundField.new(schema, schema.class.get_field("bar"))
      bound_field_2.resolve_template_attribute("errored?").should be_true
    end

    it "is able to return the result of #errors" do
      schema = Marten::Schema::BoundFieldExtSpec::TestSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      schema.valid?

      bound_field_1 = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))
      bound_field_1.resolve_template_attribute("errors").should eq bound_field_1.errors

      bound_field_2 = Marten::Schema::BoundField.new(schema, schema.class.get_field("bar"))
      bound_field_2.resolve_template_attribute("errors").should eq bound_field_2.errors
    end

    it "is able to return the result of #field" do
      schema = Marten::Schema::BoundFieldExtSpec::TestSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))
      bound_field.resolve_template_attribute("field").should eq schema.class.get_field("foo")
    end

    it "is able to return the result of #required?" do
      schema = Marten::Schema::BoundFieldExtSpec::TestSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))
      bound_field.resolve_template_attribute("required?").should be_true
    end

    it "is able to return the result of #value" do
      schema = Marten::Schema::BoundFieldExtSpec::TestSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      bound_field_1 = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))
      bound_field_1.resolve_template_attribute("value").should eq "hello"

      bound_field_2 = Marten::Schema::BoundField.new(schema, schema.class.get_field("bar"))
      bound_field_2.resolve_template_attribute("value").should be_nil
    end

    it "raises as expected if the passed attribute is not supported" do
      schema = Marten::Schema::BoundFieldExtSpec::TestSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      bound_field = Marten::Schema::BoundField.new(schema, schema.class.get_field("foo"))

      expect_raises(Marten::Template::Errors::UnknownVariable) do
        bound_field.resolve_template_attribute("unknown")
      end
    end
  end
end

module Marten::Schema::BoundFieldExtSpec
  class TestSchema < Marten::Schema
    field :foo, :string
    field :bar, :string
  end
end
