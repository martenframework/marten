require "./spec_helper"

describe Marten::DB::Query::SQL::Transformation::Month do
  describe "::transformation_name" do
    it "returns the configured lookup name" do
      Marten::DB::Query::SQL::Transformation::Month.transformation_name.should eq "month"
    end
  end

  describe "#allows?" do
    it "returns true for date/time fields" do
      Marten::DB::Query::SQL::Transformation::Month.new(TestUser.get_field("created_at")).allows?.should be_true
    end

    it "returns true for plain date fields" do
      Marten::DB::Query::SQL::Transformation::Month.new(TestUserProfile.get_field("milestone_on")).allows?
        .should be_true
    end

    it "returns false for incompatible field types" do
      Marten::DB::Query::SQL::Transformation::Month.new(TestUser.get_field("username")).allows?.should be_false
    end
  end
end
