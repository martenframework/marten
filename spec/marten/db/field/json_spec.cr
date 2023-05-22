require "./spec_helper"
require "./json_spec/**"

describe Marten::DB::Field::JSON do
  with_installed_apps Marten::DB::Field::JSONSpec::App

  describe "#default" do
    it "returns nil by default" do
      field = Marten::DB::Field::JSON.new("my_field")

      field.default.should be_nil
    end

    it "returns a parsed JSON if such value is explicitly set" do
      parsed_json = JSON.parse(%{{ "foo": "bar" }})
      field = Marten::DB::Field::JSON.new("my_field", default: parsed_json)

      field.default.should eq parsed_json
    end

    it "returns a serializable object if such value is explicitly set" do
      serializable = Marten::DB::Field::JSONSpec::SerializableTest.from_json(%{{ "a": 42, "b": "foo" }})
      field = Marten::DB::Field::JSON.new("my_field", default: serializable)

      field.default.should eq serializable
    end
  end

  describe "#from_db" do
    it "returns a string if the value is a string" do
      field = Marten::DB::Field::JSON.new("my_field", max_size: 128)
      field.from_db(%{{ "a": 42, "b": "foo" }}).should eq %{{ "a": 42, "b": "foo" }}
    end

    it "returns nil if the value is nil" do
      field = Marten::DB::Field::JSON.new("my_field", max_size: 128)
      field.from_db(nil).should be_nil
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::JSON.new("my_field", max_size: 128)

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read a string value from a DB result set" do
      field = Marten::DB::Field::JSON.new("my_field")

      Marten::DB::Connection.default.open do |db|
        db.query(%{SELECT '{ "foo": "bar" }'}) do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a String
            value.should eq %{{ "foo": "bar" }}
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::JSON.new("my_field")

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end

    it "properly handles JSON pull parser results" do
      Marten::DB::Field::JSONSpec::Record.create!(metadata: JSON.parse(%{{ "foo": "bar" }}))

      Marten::DB::Field::JSONSpec::Record.first!.metadata!.as_h.should eq({"foo" => "bar"})
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::JSON.new("my_field")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::JSON
      column.name.should eq "my_field"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.default.should be_nil
    end

    it "properly forwards the default value if it is a JSON::Any object" do
      parsed_json = JSON.parse(%{{"foo": "bar"}})
      field = Marten::DB::Field::JSON.new("my_field", default: parsed_json)
      column = field.to_column
      column.default.should eq %{{"foo":"bar"}}
    end

    it "properly forwards the default value if it is a serializable object" do
      serializable = Marten::DB::Field::JSONSpec::SerializableTest.from_json(%{{ "a": 42, "b": "foo" }})
      field = Marten::DB::Field::JSON.new("my_field", default: serializable)
      column = field.to_column
      column.default.should eq serializable.to_json
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::JSON.new("my_field")

      field.to_db(nil).should be_nil
    end

    it "returns the expected serialized JSON value if the value is a JSON::Any" do
      field = Marten::DB::Field::JSON.new("my_field")

      field.to_db(JSON.parse(%{{ "foo": "bar" }})).should eq %{{"foo":"bar"}}
    end

    it "returns the expected serialized JSON value if the value is a serializable object" do
      serializable = Marten::DB::Field::JSONSpec::SerializableTest.from_json(%{{ "a": 42, "b": "foo" }})
      field = Marten::DB::Field::JSON.new("my_field")

      field.to_db(serializable).should eq serializable.to_json
    end
  end

  describe "::contribute_to_model" do
    it "creates getter methods on the considered model that works as expected with JSON::Any objects" do
      obj = Marten::DB::Field::JSONSpec::Record.create!(
        metadata: JSON.parse(%{{ "foo": "bar" }})
      )

      obj.metadata.should be_a JSON::Any
      obj.metadata.not_nil!.as_h.should eq({"foo" => "bar"})

      obj.metadata!.should be_a JSON::Any
      obj.metadata!.as_h.should eq({"foo" => "bar"})

      obj.metadata?.should be_true
    end

    it "creates getter methods on the considered model that works as expected with serializable objects" do
      obj = Marten::DB::Field::JSONSpec::Record.create!(
        serializable_metadata: Marten::DB::Field::JSONSpec::Record::Serializable.from_json(%{{ "a": 42, "b": "foo" }})
      )

      obj.serializable_metadata.should be_a Marten::DB::Field::JSONSpec::Record::Serializable
      obj.serializable_metadata.not_nil!.a.should eq 42
      obj.serializable_metadata.not_nil!.b.should eq "foo"

      obj.serializable_metadata!.should be_a Marten::DB::Field::JSONSpec::Record::Serializable
      obj.serializable_metadata!.a.should eq 42
      obj.serializable_metadata!.b.should eq "foo"

      obj.serializable_metadata?.should be_true
    end

    it "creates getter methods on the considered model that works as expected when no values are set on the record" do
      obj = Marten::DB::Field::JSONSpec::Record.new

      obj.metadata.should be_nil
      expect_raises(NilAssertionError) { obj.metadata! }
      obj.metadata?.should be_false

      obj.serializable_metadata.should be_nil
      expect_raises(NilAssertionError) { obj.serializable_metadata! }
      obj.serializable_metadata?.should be_false
    end

    it "creates setter methods on the considered model that works as expected with JSON::Any objects" do
      obj = Marten::DB::Field::JSONSpec::Record.create!(
        metadata: JSON.parse(%{{ "foo": "bar" }})
      )

      obj.metadata = JSON.parse(%{{ "test": "xyz" }})
      obj.metadata!.as_h.should eq({"test" => "xyz"})

      obj.metadata = %{{ "a": "b" }}
      obj.metadata!.as_h.should eq({"a" => "b"})

      obj.metadata = nil
      obj.metadata.should be_nil
    end

    it "creates setter methods on the considered model that works as expected with serializable objects" do
      obj = Marten::DB::Field::JSONSpec::Record.create!(
        serializable_metadata: Marten::DB::Field::JSONSpec::Record::Serializable.from_json(%{{ "a": 42, "b": "foo" }})
      )

      obj.serializable_metadata = Marten::DB::Field::JSONSpec::Record::Serializable.from_json(%{{ "a": 1, "b": "bar" }})
      obj.serializable_metadata!.a.should eq 1
      obj.serializable_metadata!.b.should eq "bar"

      obj.serializable_metadata = %{{ "a": 2, "b": "xyz" }}
      obj.serializable_metadata!.a.should eq 2
      obj.serializable_metadata!.b.should eq "xyz"

      obj.serializable_metadata = nil
      obj.serializable_metadata.should be_nil
    end
  end
end

module Marten::DB::Field::JSONSpec
  class SerializableTest
    include ::JSON::Serializable

    property a : Int32 | Nil
    property b : ::String | Nil
  end
end
