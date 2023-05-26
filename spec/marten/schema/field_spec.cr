require "./spec_helper"

describe Marten::Schema::Field do
  describe "#registry" do
    it "returns the expected field abstractions" do
      Marten::Schema::Field.registry.size.should eq 11
      Marten::Schema::Field.registry["bool"].should eq Marten::Schema::Field::Bool
      Marten::Schema::Field.registry["date"].should eq Marten::Schema::Field::Date
      Marten::Schema::Field.registry["date_time"].should eq Marten::Schema::Field::DateTime
      Marten::Schema::Field.registry["duration"].should eq Marten::Schema::Field::Duration
      Marten::Schema::Field.registry["email"].should eq Marten::Schema::Field::Email
      Marten::Schema::Field.registry["file"].should eq Marten::Schema::Field::File
      Marten::Schema::Field.registry["float"].should eq Marten::Schema::Field::Float
      Marten::Schema::Field.registry["int"].should eq Marten::Schema::Field::Int
      Marten::Schema::Field.registry["json"].should eq Marten::Schema::Field::JSON
      Marten::Schema::Field.registry["string"].should eq Marten::Schema::Field::String
      Marten::Schema::Field.registry["uuid"].should eq Marten::Schema::Field::UUID
    end
  end
end
