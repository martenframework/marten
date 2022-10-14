require "./spec_helper"

describe Marten::Routing::Rule::Map do
  describe "#resolve" do
    it "is able to resolve a path that does not contain any parameter" do
      map = Marten::Routing::Map.new
      map.path("/xyz", Marten::Handlers::Base, name: "xyz")

      rule = Marten::Routing::Rule::Map.new("/home", map, name: "inc")

      match = rule.resolve("/home/xyz")
      match.should be_a Marten::Routing::Match
      match = match.as(Marten::Routing::Match)
      match.handler.should eq Marten::Handlers::Base
      match.kwargs.should be_empty
    end

    it "is able to resolve a path that contains parameters" do
      map = Marten::Routing::Map.new
      map.path("/count/<number:int>/display", Marten::Handlers::Base, name: "xyz")

      rule = Marten::Routing::Rule::Map.new("/home/xyz/<sid:slug>", map, name: "inc")

      match = rule.resolve("/home/xyz/my-slug/count/42/display")
      match.should be_a Marten::Routing::Match
      match = match.as(Marten::Routing::Match)
      match.handler.should eq Marten::Handlers::Base
      match.kwargs.should eq({"sid" => "my-slug", "number" => 42})
    end

    it "returns nil if the path does not match the considered rule" do
      map = Marten::Routing::Map.new
      map.path("/count/<number:int>/display", Marten::Handlers::Base, name: "xyz")

      rule = Marten::Routing::Rule::Map.new("/home/xyz/<sid:slug>", map, name: "inc")

      rule.resolve("/home").should be_nil
    end

    it "returns nil if the path does not match the considered rule at the including path level" do
      map = Marten::Routing::Map.new
      map.path("/count/<number:int>/display", Marten::Handlers::Base, name: "xyz")

      rule = Marten::Routing::Rule::Map.new("/home/xyz/<sid:slug>", map, name: "inc")

      rule.resolve("/home/xyz/not+a+slug/count/42/display").should be_nil
    end

    it "returns nil if the path does not match the considered rule at the included path level" do
      map = Marten::Routing::Map.new
      map.path("/count/<number:int>/display", Marten::Handlers::Base, name: "xyz")

      rule = Marten::Routing::Rule::Map.new("/home/xyz/<sid:slug>", map, name: "inc")

      rule.resolve("/home/xyz/a-slug/count/not-a-number/display").should be_nil
    end
  end

  describe "#reversers" do
    it "returns an array containing a reversers built from the enclosing rule and the sub paths" do
      map = Marten::Routing::Map.new
      map.path("/count/<number:int>/display", Marten::Handlers::Base, name: "count")
      map.path("/xyz", Marten::Handlers::Base, name: "xyz")

      rule = Marten::Routing::Rule::MapSpec::TestMapRule.new("/home/xyz/<sid:slug>", map, name: "inc")

      reversers = rule.exposed_reversers

      reversers.should be_a Array(Marten::Routing::Reverser)
      reversers.size.should eq 2

      reversers[0].name.should eq "inc:count"
      reversers[0].path_for_interpolation.should eq "/home/xyz/%{sid}/count/%{number}/display"
      reversers[0].parameters.size.should eq 2
      reversers[0].parameters["number"].should be_a Marten::Routing::Parameter::Integer
      reversers[0].parameters["sid"].should be_a Marten::Routing::Parameter::Slug

      reversers[1].name.should eq "inc:xyz"
      reversers[1].path_for_interpolation.should eq "/home/xyz/%{sid}/xyz"
      reversers[1].parameters.size.should eq 1
      reversers[1].parameters["sid"].should be_a Marten::Routing::Parameter::Slug
    end
  end
end

module Marten::Routing::Rule::MapSpec
  class TestMapRule < Marten::Routing::Rule::Map
    def exposed_reversers
      reversers
    end
  end
end
