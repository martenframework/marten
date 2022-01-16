require "./spec_helper"

describe Marten::Schema::Field do
  describe "#registry" do
    it "returns the expected field abstractions" do
      Marten::Schema::Field.registry.size.should eq 1
      Marten::Schema::Field.registry["string"].should eq Marten::Schema::Field::String
    end
  end
end
