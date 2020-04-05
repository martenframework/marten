require "./spec_helper"

describe Marten::Routing::Match do
  describe "::view" do
    it "returns the associated view class" do
      match = Marten::Routing::Match.new(
        Marten::Routing::MatchSpec::TestView,
        { "id" => 123 } of String => Marten::Routing::Parameter::Types
      )
      match.view.should eq Marten::Routing::MatchSpec::TestView
    end
  end

  describe "::kwargs" do
    it "returns the associated view parameters" do
      match = Marten::Routing::Match.new(
        Marten::Routing::MatchSpec::TestView,
        { "id" => 123 } of String => Marten::Routing::Parameter::Types
      )
      match.kwargs.should eq({ "id" => 123 })
    end
  end
end

module Marten::Routing::MatchSpec
  class TestView < Marten::Views::Base
  end
end
