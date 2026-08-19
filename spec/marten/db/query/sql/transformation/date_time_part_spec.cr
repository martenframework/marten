require "./spec_helper"

describe Marten::DB::Query::SQL::Transformation::DateTimePart do
  describe "#apply" do
    it "localizes datetime columns before applying the backend extraction SQL" do
      conn = Marten::DB::Connection.default
      field = TestUser.get_field("created_at")
      year = Marten::DB::Query::SQL::Transformation::Year.new(field)

      year.apply(conn, "test_users.created_at").should eq(
        conn.left_operand_for_transformation(
          conn.local_datetime_expression("test_users.created_at"),
          "year"
        )
      )
    end

    it "does not localize plain date columns" do
      conn = Marten::DB::Connection.default
      field = TestUserProfile.get_field("milestone_on")
      year = Marten::DB::Query::SQL::Transformation::Year.new(field)

      year.apply(conn, "test_user_profiles.milestone_on").should eq(
        conn.left_operand_for_transformation("test_user_profiles.milestone_on", "year")
      )
    end
  end

  describe "#bind_parameter_value" do
    it "coerces integer widths to Int64" do
      field = TestUser.get_field("created_at")
      year = Marten::DB::Query::SQL::Transformation::DateTimePartSpec::SampleTransformation.new(field)

      year.bind_parameter_value(42).should eq 42_i64
      year.bind_parameter_value(42_i64).should eq 42_i64
    end

    it "returns nil for nil" do
      field = TestUser.get_field("created_at")
      year = Marten::DB::Query::SQL::Transformation::DateTimePartSpec::SampleTransformation.new(field)

      year.bind_parameter_value(nil).should be_nil
    end

    it "raises when the value is not an integer type" do
      field = TestUser.get_field("created_at")
      year = Marten::DB::Query::SQL::Transformation::DateTimePartSpec::SampleTransformation.new(field)

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition) do
        year.bind_parameter_value("not-an-int")
      end
    end
  end
end

module Marten::DB::Query::SQL::Transformation::DateTimePartSpec
  class SampleTransformation < Marten::DB::Query::SQL::Transformation::DateTimePart
    transformation_name "__transformation_spec_sample__"

    def allows? : Bool
      true
    end
  end
end
