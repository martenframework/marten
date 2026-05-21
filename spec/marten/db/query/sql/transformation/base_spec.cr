require "./spec_helper"

describe Marten::DB::Query::SQL::Transformation::Base do
  describe "::transformation_name" do
    it "returns the configured lookup name for a concrete subclass" do
      Marten::DB::Query::SQL::Transformation::BaseSpec::SampleTransformation.transformation_name.should eq(
        "__transformation_spec_sample__"
      )
    end
  end

  describe "#apply" do
    it "delegates SQL generation to the connection using the subclass lookup name" do
      conn = Marten::DB::Connection.default
      field = TestUser.get_field("created_at")
      year = Marten::DB::Query::SQL::Transformation::Year.new(field)

      year.apply(conn, "test_users.created_at").should eq(
        conn.left_operand_for_transformation("test_users.created_at", "year")
      )
    end
  end
end

module Marten::DB::Query::SQL::Transformation::BaseSpec
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
