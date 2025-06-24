require "./spec_helper"

describe Marten::DB::Query::SQL::Annotation::Base do
  describe "#clone" do
    it "returns a new instance with the same attributes" do
      ann = Marten::DB::Query::SQL::Annotation::Count.new(
        field: Marten::DB::Field::Int.new("test"),
        alias_name: "test",
        distinct: true,
        alias_prefix: "test_prefix",
      )

      clone = ann.clone

      clone.should_not be ann

      clone.field.should eq ann.field
      clone.alias_name.should eq ann.alias_name
      clone.distinct?.should eq ann.distinct?
      clone.alias_prefix.should eq ann.alias_prefix
    end
  end
end
