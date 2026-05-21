require "./spec_helper"

describe Marten::DB::Query::SQL::Transformation::Day do
  describe "::transformation_name" do
    it "returns the configured lookup name" do
      Marten::DB::Query::SQL::Transformation::Day.transformation_name.should eq "day"
    end
  end

  describe "#allows?" do
    it "returns true for date/time fields" do
      Marten::DB::Query::SQL::Transformation::Day.new(TestUser.get_field("created_at")).allows?.should be_true
    end

    it "returns true for plain date fields" do
      Marten::DB::Query::SQL::Transformation::Day.new(TestUserProfile.get_field("milestone_on")).allows?
        .should be_true
    end

    it "returns false for incompatible field types" do
      Marten::DB::Query::SQL::Transformation::Day.new(TestUser.get_field("username")).allows?.should be_false
    end
  end
end
