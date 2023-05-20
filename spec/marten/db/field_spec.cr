require "./spec_helper"

describe Marten::DB::Field do
  describe "#registry" do
    it "returns the expected field abstractions" do
      Marten::DB::Field.registry.size.should eq 16
      Marten::DB::Field.registry["big_int"].should eq Marten::DB::Field::BigInt
      Marten::DB::Field.registry["bool"].should eq Marten::DB::Field::Bool
      Marten::DB::Field.registry["date"].should eq Marten::DB::Field::Date
      Marten::DB::Field.registry["date_time"].should eq Marten::DB::Field::DateTime
      Marten::DB::Field.registry["duration"].should eq Marten::DB::Field::Duration
      Marten::DB::Field.registry["email"].should eq Marten::DB::Field::Email
      Marten::DB::Field.registry["file"].should eq Marten::DB::Field::File
      Marten::DB::Field.registry["float"].should eq Marten::DB::Field::Float
      Marten::DB::Field.registry["int"].should eq Marten::DB::Field::Int
      Marten::DB::Field.registry["json"].should eq Marten::DB::Field::JSON
      Marten::DB::Field.registry["many_to_many"].should eq Marten::DB::Field::ManyToMany
      Marten::DB::Field.registry["many_to_one"].should eq Marten::DB::Field::ManyToOne
      Marten::DB::Field.registry["one_to_one"].should eq Marten::DB::Field::OneToOne
      Marten::DB::Field.registry["string"].should eq Marten::DB::Field::String
      Marten::DB::Field.registry["text"].should eq Marten::DB::Field::Text
      Marten::DB::Field.registry["uuid"].should eq Marten::DB::Field::UUID
    end
  end
end
