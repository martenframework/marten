require "./spec_helper"

describe Marten::Schema::Field::UUID do
  describe "#deserialize" do
    it "returns the UUID corresponding to the passed string value" do
      field = Marten::Schema::Field::UUID.new("test_field")
      field.deserialize("d764c9a6-439b-11eb-b378-0242ac130002").should eq(
        UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")
      )
    end

    it "returns the UUID corresponding to the passed JSON string value" do
      field = Marten::Schema::Field::UUID.new("test_field")
      field.deserialize(JSON.parse(%{"d764c9a6-439b-11eb-b378-0242ac130002"})).should eq(
        UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")
      )
    end

    it "returns nil if the passed value is an empty value" do
      field = Marten::Schema::Field::UUID.new("test_field")
      field.deserialize(nil).should be_nil
      field.deserialize("").should be_nil
    end

    it "returns nil if the value is nil" do
      field = Marten::Schema::Field::UUID.new("test_field")
      field.deserialize(nil).should be_nil
    end

    it "returns nil if the value is an empty string" do
      field = Marten::Schema::Field::UUID.new("test_field")
      field.deserialize("").should be_nil
    end

    it "raises as expected if the passed value has an unexpected type" do
      field = Marten::Schema::Field::UUID.new("test_field")
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize(true) }
    end

    it "raises as expected if the passed value is not an UUID string" do
      field = Marten::Schema::Field::UUID.new("test_field")
      expect_raises(Marten::Schema::Errors::UnexpectedFieldValue) { field.deserialize("foo bar") }
    end
  end

  describe "#serialize" do
    it "returns the string representation of the passed value" do
      field = Marten::Schema::Field::UUID.new("test_field")
      field.serialize(UUID.new("d764c9a6-439b-11eb-b378-0242ac130002")).should eq "d764c9a6-439b-11eb-b378-0242ac130002"
    end

    it "returns nil if the passed value is nil" do
      field = Marten::Schema::Field::UUID.new("test_field")
      field.serialize(nil).should be_nil
    end
  end
end
