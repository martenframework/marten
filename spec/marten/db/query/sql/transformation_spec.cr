require "./spec_helper"

describe Marten::DB::Query::SQL::Transformation do
  describe "::allows?" do
    it "returns true when the transformation applies to the field type" do
      created_at = TestUser.get_field("created_at")
      Marten::DB::Query::SQL::Transformation.allows?(created_at, "year").should be_true
      Marten::DB::Query::SQL::Transformation.allows?(created_at, "hour").should be_true
    end

    it "returns false for incompatible field types" do
      username = TestUser.get_field("username")
      Marten::DB::Query::SQL::Transformation.allows?(username, "year").should be_false
      Marten::DB::Query::SQL::Transformation.allows?(username, "hour").should be_false
    end

    it "returns false for unknown transformation names" do
      Marten::DB::Query::SQL::Transformation.allows?(TestUser.get_field("created_at"), "unknown").should be_false
    end
  end

  describe "::register" do
    it "allows registering a transformation implementation" do
      Marten::DB::Query::SQL::Transformation.register(
        Marten::DB::Query::SQL::TransformationSpec::SampleTransformation
      )
      Marten::DB::Query::SQL::Transformation.registry["__transformation_spec_sample__"].should eq(
        Marten::DB::Query::SQL::TransformationSpec::SampleTransformation
      )
    end
  end

  describe "::registered?" do
    it "returns true for known transformation lookup names" do
      Marten::DB::Query::SQL::Transformation.registered?("year").should be_true
    end

    it "returns false for unknown lookup names" do
      Marten::DB::Query::SQL::Transformation.registered?("not_a_real_transformation").should be_false
    end
  end

  describe "::registry" do
    it "returns built-in calendar transformation classes by lookup name" do
      Marten::DB::Query::SQL::Transformation.registry["year"].should eq Marten::DB::Query::SQL::Transformation::Year
      Marten::DB::Query::SQL::Transformation.registry["month"].should eq Marten::DB::Query::SQL::Transformation::Month
      Marten::DB::Query::SQL::Transformation.registry["day"].should eq Marten::DB::Query::SQL::Transformation::Day
      Marten::DB::Query::SQL::Transformation.registry["hour"].should eq Marten::DB::Query::SQL::Transformation::Hour
      Marten::DB::Query::SQL::Transformation.registry["minute"].should eq Marten::DB::Query::SQL::Transformation::Minute
      Marten::DB::Query::SQL::Transformation.registry["second"].should eq Marten::DB::Query::SQL::Transformation::Second
    end
  end
end

module Marten::DB::Query::SQL::TransformationSpec
  class SampleTransformation < Marten::DB::Query::SQL::Transformation::Base
    transformation_name "__transformation_spec_sample__"

    def allows? : Bool
      true
    end

    def bind_parameter_value(value : Field::Any) : ::DB::Any
      nil
    end
  end
end
