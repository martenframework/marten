require "./spec_helper"

describe Marten::Routing::Rule::Path do
  describe "#resolve" do
    it "is able to resolve a path that does not contain any parameter" do
      rule = Marten::Routing::Rule::Path.new("/home/xyz", Marten::Handlers::Base, name: "home_xyz")
      match = rule.resolve("/home/xyz")
      match.should be_a Marten::Routing::Match
      match = match.as(Marten::Routing::Match)
      match.handler.should eq Marten::Handlers::Base
      match.kwargs.should be_empty
    end

    it "is able to resolve a path that contains parameters" do
      rule = Marten::Routing::Rule::Path.new(
        "/home/xyz/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "home_xyz"
      )
      match = rule.resolve("/home/xyz/my-slug/count/42/display")
      match.should be_a Marten::Routing::Match
      match = match.as(Marten::Routing::Match)
      match.handler.should eq Marten::Handlers::Base
      match.kwargs.should eq({"sid" => "my-slug", "number" => 42})
    end

    it "returns nil if the path does not match the considered rule" do
      rule = Marten::Routing::Rule::Path.new(
        "/home/xyz/<sid:slug>/count/<number:int>/display",
        Marten::Handlers::Base,
        name: "home_xyz"
      )
      rule.resolve("/home").should be_nil
    end
  end

  describe "#reversers" do
    it "returns an array containing a single reverser for the considered path" do
      rule = Marten::Routing::Rule::PathSpec::TestPathRule.new(
        "/home/xyz/<sid:slug>/display",
        Marten::Handlers::Base,
        name: "home_xyz"
      )

      reversers = rule.exposed_reversers

      reversers.should be_a Array(Marten::Routing::Reverser)
      reversers.size.should eq 1

      reverser = reversers.first
      reverser.name.should eq "home_xyz"
      reverser.path_for_interpolation.should eq "/home/xyz/%{sid}/display"
      reverser.parameters.size.should eq 1
      reverser.parameters["sid"].should be_a Marten::Routing::Parameter::Slug
    end
  end
end

module Marten::Routing::Rule::PathSpec
  class TestPathRule < Marten::Routing::Rule::Path
    def exposed_reversers
      reversers
    end
  end
end
