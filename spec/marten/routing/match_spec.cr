require "./spec_helper"

describe Marten::Routing::Match do
  describe "#handler" do
    it "returns the associated handler class" do
      match = Marten::Routing::Match.new(
        handler: Marten::Routing::MatchSpec::TestHandler,
        rule: Marten::Routing::Rule::Path.new(name: "test", handler: Marten::Routing::MatchSpec::TestHandler, path: "/test"),
        kwargs: Marten::Routing::MatchParameters{"id" => 123},
      )
      match.handler.should eq Marten::Routing::MatchSpec::TestHandler
    end
  end

  describe "#kwargs" do
    it "returns the associated handler parameters" do
      match = Marten::Routing::Match.new(
        handler: Marten::Routing::MatchSpec::TestHandler,
        rule: Marten::Routing::Rule::Path.new(name: "test", handler: Marten::Routing::MatchSpec::TestHandler, path: "/test"),
        kwargs: Marten::Routing::MatchParameters{"id" => 123},
      )
      match.kwargs.should eq({"id" => 123})
    end
  end
end

module Marten::Routing::MatchSpec
  class TestHandler < Marten::Handlers::Base
  end
end
