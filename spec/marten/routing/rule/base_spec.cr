require "./spec_helper"

describe Marten::Routing::Rule::Base do
  describe "#path_to_regex" do
    it "is able to process a path without parameters" do
      rule = Marten::Routing::Rule::BaseSpec::TestRule.new("/path/xyz")
      rule.regex.should eq /^\/path\/xyz/
      rule.path_for_interpolation.should eq "/path/xyz"
      rule.parameters.empty?.should be_true
    end

    it "is able to process a path with parameters" do
      rule = Marten::Routing::Rule::BaseSpec::TestRule.new("/path/xyz/<id:int>/metadata/<meta:slug>")
      rule.regex.should(
        eq(/^\/path\/xyz\/(?P<id>(?-imsx:[0-9]+))\/metadata\/(?P<meta>(?-imsx:[-a-zA-Z0-9_]+))/)
      )
      rule.path_for_interpolation.should eq "/path/xyz/%{id}/metadata/%{meta}"
      rule.parameters.size.should eq 2
      rule.parameters["id"].should be_a Marten::Routing::Parameter::Integer
      rule.parameters["meta"].should be_a Marten::Routing::Parameter::Slug
    end

    it "is able to process a root path" do
      rule = Marten::Routing::Rule::BaseSpec::TestRule.new("/")
      rule.regex.should eq /^\//
      rule.path_for_interpolation.should eq "/"
      rule.parameters.empty?.should be_true
    end

    it "raises if it encounters a path with a param that is not a valid Crystal variable name" do
      expect_raises(Marten::Routing::Errors::InvalidParameterName) do
        Marten::Routing::Rule::BaseSpec::TestRule.new("/path/xyz/<4var:int>")
      end
    end

    it "raises if it encounters a path with a param that is associated with an unknown type" do
      expect_raises(Marten::Routing::Errors::UnknownParameterType) do
        Marten::Routing::Rule::BaseSpec::TestRule.new("/path/xyz/<id:unknown>")
      end
    end
  end
end

module Marten::Routing::Rule::BaseSpec
  class TestRule < Marten::Routing::Rule::Base
    @regex : Regex
    @path_for_interpolation : String
    @parameters : Hash(String, Marten::Routing::Parameter::Base)

    getter regex
    getter path_for_interpolation
    getter parameters

    def initialize(path : String)
      @regex, @path_for_interpolation, @parameters = path_to_regex(path)
    end

    def resolve(path : String) : Nil | Match
      nil
    end

    def reversers : Array(Marten::Routing::Reverser)
      [] of Marten::Routing::Reverser
    end

    def name : String
      "test"
    end
  end
end
