require "./spec_helper"

describe Marten::Schema do
  describe "#new" do
    it "allows to initialize a schema from a handler's routing paramters" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::Routing::MatchParameters{"id" => 42, "foo" => "bar"})
      schema.should be_truthy
    end
  end

  describe "::inherited" do
    it "ensures that the schema inherits its parent fields" do
      Marten::SchemaSpec::SubSchema.fields.size.should eq 4
      Marten::SchemaSpec::SubSchema.fields.map(&.id).should eq(["foo", "bar", "number", "acknowledged"])
    end
  end

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

  describe "#[]" do
    it "returns the bound field for the passed field identifier string" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      schema["foo"].should be_a Marten::Schema::BoundField
      schema["foo"].id.should eq "foo"
      schema["foo"].value.should eq "hello"

      schema["bar"].should be_a Marten::Schema::BoundField
      schema["bar"].id.should eq "bar"
      schema["bar"].value.should be_nil
    end

    it "returns the bound field for the passed field identifier symbol" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      schema[:foo].should be_a Marten::Schema::BoundField
      schema[:foo].id.should eq "foo"
      schema[:foo].value.should eq "hello"

      schema[:bar].should be_a Marten::Schema::BoundField
      schema[:bar].id.should eq "bar"
      schema[:bar].value.should be_nil
    end

    it "raises UnknownField if the field is unknown" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      expect_raises(Marten::Schema::Errors::UnknownField) { schema["unknown"] }
      expect_raises(Marten::Schema::Errors::UnknownField) { schema[:unknown] }
    end
  end

  describe "#[]?" do
    it "returns the bound field for the passed field identifier string" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      schema["foo"]?.should be_a Marten::Schema::BoundField
      schema["foo"]?.not_nil!.id.should eq "foo"
      schema["foo"]?.not_nil!.value.should eq "hello"

      schema["bar"]?.should be_a Marten::Schema::BoundField
      schema["bar"]?.not_nil!.id.should eq "bar"
      schema["bar"]?.not_nil!.value.should be_nil
    end

    it "returns the bound field for the passed field identifier symbol" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      schema[:foo]?.should be_a Marten::Schema::BoundField
      schema[:foo]?.not_nil!.id.should eq "foo"
      schema[:foo]?.not_nil!.value.should eq "hello"

      schema[:bar]?.should be_a Marten::Schema::BoundField
      schema[:bar]?.not_nil!.id.should eq "bar"
      schema[:bar]?.not_nil!.value.should be_nil
    end

    it "returns nil if the field is unknown" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})

      schema["unknown"]?.should be_nil
      schema[:unknown]?.should be_nil
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

    it "returns the initial value associated with a given field if no value is found in the current data" do
      schema = Marten::SchemaSpec::SimpleSchema.new(
        data: Marten::HTTP::Params::Data.new,
        initial: Marten::Schema::DataHash{"foo" => "hello"}
      )
      schema.get_field_value("foo").should eq "hello"
    end

    it "raises if the field cannot be found" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      expect_raises(Marten::Schema::Errors::UnknownField) { schema.get_field_value("unknown") }
    end
  end

  describe "#validated_data" do
    it "returns an empty hash if the validation did not run yet" do
      schema = Marten::SchemaSpec::SimpleSchema.new(Marten::HTTP::Params::Data{"foo" => ["hello"]})
      schema.validated_data.should be_empty
    end

    it "returns a hash containing the deserialized data if the validation ran previously" do
      schema = Marten::SchemaSpec::SimpleSchema.new(
        Marten::HTTP::Params::Data{"foo" => ["  hello  "], "bar" => ["   world  "]}
      )
      schema.valid?
      schema.validated_data.size.should eq 2
      schema.validated_data["foo"].should eq "hello"
      schema.validated_data["bar"].should eq "world"
    end
  end
end

module Marten::SchemaSpec
  class SimpleSchema < Marten::Schema
    field :foo, :string
    field :bar, :string, max_size: 200
  end

  class SubSchema < SimpleSchema
    field :number, :int
    field :acknowledged, :bool
  end
end
