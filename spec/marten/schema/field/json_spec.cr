require "./spec_helper"

describe Marten::Schema::Field::JSON do
  describe "#deserialize" do
    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::JSON.new("test_field")

      field.deserialize(nil).should be_nil
    end

    it "returns nil if the passed value is a blank string" do
      field = Marten::Schema::Field::JSON.new("test_field")

      field.deserialize("").should be_nil
    end

    it "returns the parsed JSON if the value is a string" do
      field = Marten::Schema::Field::JSON.new("test_field")

      field.deserialize(%{{ "foo": "bar" }}).should eq JSON.parse(%{{ "foo": "bar" }})
    end

    it "returns the parsed serializable if the value is a string" do
      field = Marten::Schema::Field::JSON.new(
        "test_field",
        serializable: Marten::Schema::Field::JSONSpec::SerializableTest
      )

      deserialized = field.deserialize(%{{ "a": 42, "b": "foo"}})
      deserialized.should be_a Marten::Schema::Field::JSONSpec::SerializableTest

      deserialized = deserialized.as(Marten::Schema::Field::JSONSpec::SerializableTest)
      deserialized.a.should eq 42
      deserialized.b.should eq "foo"
    end

    it "returns the parsed JSON if the value is a JSON value" do
      field = Marten::Schema::Field::JSON.new("test_field")

      field.deserialize(JSON.parse(%{{ "foo": "bar" }})).should eq JSON.parse(%{{ "foo": "bar" }})
    end

    it "returns the parsed serializable if the value is a JSON value" do
      field = Marten::Schema::Field::JSON.new(
        "test_field",
        serializable: Marten::Schema::Field::JSONSpec::SerializableTest
      )

      deserialized = field.deserialize(JSON.parse(%{{ "a": 42, "b": "foo" }}))
      deserialized.should be_a Marten::Schema::Field::JSONSpec::SerializableTest

      deserialized = deserialized.as(Marten::Schema::Field::JSONSpec::SerializableTest)
      deserialized.a.should eq 42
      deserialized.b.should eq "foo"
    end

    it "raises in case the passed value has an unexpected type" do
      field = Marten::Schema::Field::JSON.new("test_field")

      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize(true) }
    end

    it "raises in case the passed value is not a valid JSON value" do
      field = Marten::Schema::Field::JSON.new("test_field")

      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize("this is bad") }
    end

    it "raises in case the passed value does not comply to the specified serializable" do
      field = Marten::Schema::Field::JSON.new(
        "test_field",
        serializable: Marten::Schema::Field::JSONSpec::SerializableTest
      )

      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize(%{{ "a": "foo", "b": 42 }}) }
    end
  end

  describe "#serialize" do
    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::JSON.new("test_field")

      field.serialize(nil).should be_nil
    end

    it "returns the JSON representation of the passed JSON::Any object" do
      field = Marten::Schema::Field::JSON.new("test_field")

      field.serialize(JSON.parse(%{{ "foo": "bar" }})).should eq JSON.parse(%{{ "foo": "bar" }}).to_json
    end

    it "returns the JSON representation of the passed JSON::Serializable object" do
      field = Marten::Schema::Field::JSON.new(
        "test_field",
        serializable: Marten::Schema::Field::JSONSpec::SerializableTest
      )

      obj = Marten::Schema::Field::JSONSpec::SerializableTest.from_json(%{{ "a": 42, "b": "foo"}})

      field.serialize(obj).should eq obj.to_json
    end

    it "raises if the passed value has an unexpected type" do
      field = Marten::Schema::Field::JSON.new("test_field")

      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.serialize(true) }
    end
  end

  describe "#perform_validation" do
    it "validates a valid JSON value" do
      schema = Marten::Schema::Field::JSONSpec::SchemaTest.new(
        Marten::Schema::DataHash{"metadata" => %{{ "foo": "bar" }}}
      )

      field = Marten::Schema::Field::JSON.new("metadata")
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "validates a valid serializable object JSON value" do
      schema = Marten::Schema::Field::JSONSpec::SchemaTest.new(
        Marten::Schema::DataHash{"metadata_serializable" => %{{ "a": 42, "b": "foo"}}}
      )

      field = Marten::Schema::Field::JSON.new(
        "metadata_serializable",
        serializable: Marten::Schema::Field::JSONSpec::SerializableTest
      )
      field.perform_validation(schema)

      schema.errors.should be_empty
    end

    it "does not validate an invalid JSON value" do
      schema = Marten::Schema::Field::JSONSpec::SchemaTest.new(
        Marten::Schema::DataHash{"metadata" => "this is bad"}
      )

      field = Marten::Schema::Field::JSON.new("metadata")
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "metadata"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.json.errors.invalid")
    end

    it "does not validate an invalid serializable object JSON value" do
      schema = Marten::Schema::Field::JSONSpec::SchemaTest.new(
        Marten::Schema::DataHash{"metadata_serializable" => %{{ "a": "foo", "b": 42}}}
      )

      field = Marten::Schema::Field::JSON.new(
        "metadata_serializable",
        serializable: Marten::Schema::Field::JSONSpec::SerializableTest
      )
      field.perform_validation(schema)

      schema.errors.size.should eq 1
      schema.errors.first.field.should eq "metadata_serializable"
      schema.errors.first.message.should eq I18n.t("marten.schema.field.json.errors.invalid")
    end
  end

  describe "::contribute_to_schema" do
    it "sets up the expected getter method allowing to fetch type-safe validated field data" do
      schema = Marten::Schema::Field::JSONSpec::SchemaTest.new(
        Marten::Schema::DataHash{
          "metadata"              => %{{ "foo": "bar" }},
          "metadata_serializable" => %{{ "a": 42, "b": "foo"}},
        }
      )

      schema.metadata.should be_nil
      expect_raises(NilAssertionError) { schema.metadata! }
      schema.metadata?.should be_false

      schema.metadata_serializable.should be_nil
      schema.metadata_serializable?.should be_false
      expect_raises(NilAssertionError) { schema.metadata_serializable! }

      schema.valid?.should be_true

      schema.metadata.should eq JSON.parse(%{{ "foo": "bar" }})
      schema.metadata!.should eq JSON.parse(%{{ "foo": "bar" }})
      schema.metadata?.should be_true
      typeof(schema.metadata).should eq ::JSON::Any?

      schema.metadata_serializable.try(&.a).should eq 42
      schema.metadata_serializable.try(&.b).should eq "foo"
      schema.metadata_serializable!.a.should eq 42
      schema.metadata_serializable!.b.should eq "foo"
      schema.metadata_serializable?.should be_true
      typeof(schema.metadata_serializable).should eq Marten::Schema::Field::JSONSpec::SerializableTest?
    end
  end
end

module Marten::Schema::Field::JSONSpec
  class SerializableTest
    include ::JSON::Serializable

    property a : Int32 | Nil
    property b : ::String | Nil
  end

  class SchemaTest < Marten::Schema
    field :metadata, :json, required: false
    field :metadata_serializable, :json, serializable: SerializableTest, required: false
  end
end
