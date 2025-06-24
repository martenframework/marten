require "./spec_helper"

describe Marten::DB::Query::SQL::Annotation do
  describe "::register" do
    it "allows to register a new annotation implementation" do
      Marten::DB::Query::SQL::Annotation.register(Marten::DB::Query::SQL::AnnotationSpec::TestAnnotation)
      Marten::DB::Query::SQL::Annotation.registry["test_annotation"].should eq(
        Marten::DB::Query::SQL::AnnotationSpec::TestAnnotation
      )
    end
  end

  describe "::registry" do
    it "returns the registered annotation implementations" do
      Marten::DB::Query::SQL::Annotation.registry["average"].should eq(Marten::DB::Query::SQL::Annotation::Average)
      Marten::DB::Query::SQL::Annotation.registry["count"].should eq(Marten::DB::Query::SQL::Annotation::Count)
      Marten::DB::Query::SQL::Annotation.registry["maximum"].should eq(Marten::DB::Query::SQL::Annotation::Maximum)
      Marten::DB::Query::SQL::Annotation.registry["minimum"].should eq(Marten::DB::Query::SQL::Annotation::Minimum)
      Marten::DB::Query::SQL::Annotation.registry["sum"].should eq(Marten::DB::Query::SQL::Annotation::Sum)
    end
  end
end

module Marten::DB::Query::SQL::AnnotationSpec
  class TestAnnotation < Marten::DB::Query::SQL::Annotation::Base
    def from_db_result_set(result_set : ::DB::ResultSet)
      result_set.read(Int64 | Int32 | Int16 | Int8 | Float64 | Float32)
    end

    def to_sql : String
      "TEST_ANNOTATION"
    end
  end
end
