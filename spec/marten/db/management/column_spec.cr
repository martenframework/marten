require "./spec_helper"

describe Marten::DB::Management::Column do
  describe "#registry" do
    it "returns the expected column abstractions" do
      Marten::DB::Management::Column.registry.size.should eq 11
      Marten::DB::Management::Column.registry["big_int"].should eq Marten::DB::Management::Column::BigInt
      Marten::DB::Management::Column.registry["bool"].should eq Marten::DB::Management::Column::Bool
      Marten::DB::Management::Column.registry["date"].should eq Marten::DB::Management::Column::Date
      Marten::DB::Management::Column.registry["date_time"].should eq Marten::DB::Management::Column::DateTime
      Marten::DB::Management::Column.registry["float"].should eq Marten::DB::Management::Column::Float
      Marten::DB::Management::Column.registry["reference"].should eq Marten::DB::Management::Column::Reference
      Marten::DB::Management::Column.registry["int"].should eq Marten::DB::Management::Column::Int
      Marten::DB::Management::Column.registry["json"].should eq Marten::DB::Management::Column::JSON
      Marten::DB::Management::Column.registry["string"].should eq Marten::DB::Management::Column::String
      Marten::DB::Management::Column.registry["text"].should eq Marten::DB::Management::Column::Text
      Marten::DB::Management::Column.registry["uuid"].should eq Marten::DB::Management::Column::UUID
    end
  end
end
