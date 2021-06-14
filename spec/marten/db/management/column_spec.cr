require "./spec_helper"

describe Marten::DB::Management::Column do
  describe "#registry" do
    it "returns the expected column abstractions" do
      Marten::DB::Management::Column.registry["auto"].should eq Marten::DB::Management::Column::Auto
      Marten::DB::Management::Column.registry["big_auto"].should eq Marten::DB::Management::Column::BigAuto
      Marten::DB::Management::Column.registry["big_int"].should eq Marten::DB::Management::Column::BigInt
      Marten::DB::Management::Column.registry["bool"].should eq Marten::DB::Management::Column::Bool
      Marten::DB::Management::Column.registry["date_time"].should eq Marten::DB::Management::Column::DateTime
      Marten::DB::Management::Column.registry["foreign_key"].should eq Marten::DB::Management::Column::ForeignKey
      Marten::DB::Management::Column.registry["string"].should eq Marten::DB::Management::Column::String
      Marten::DB::Management::Column.registry["text"].should eq Marten::DB::Management::Column::Text
      Marten::DB::Management::Column.registry["uuid"].should eq Marten::DB::Management::Column::UUID
    end
  end
end
