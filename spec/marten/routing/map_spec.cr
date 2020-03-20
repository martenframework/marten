require "./spec_helper"

describe Marten::Routing::Match do
  describe "#path" do
    it "raises if the inserted rule doesn't have a valid name" do
      map = Marten::Routing::Map.new
      expect_raises(Marten::Routing::Errors::InvalidRuleName) do
        map.path("/", Marten::Views::Base, name: ":$in~")
      end
    end

    it "raises if the inserted rule is an empty string" do
      map = Marten::Routing::Map.new
      expect_raises(Marten::Routing::Errors::InvalidRuleName) do
        map.path("/", Marten::Views::Base, name: "")
      end
    end

    it "raises if the inserted rule name is already taken" do
      map = Marten::Routing::Map.new
      map.path("/", Marten::Views::Base, name: "home")
      expect_raises(Marten::Routing::Errors::InvalidRuleName) do
        map.path("/bis", Marten::Views::Base, name: "home")
      end
    end

    it "raises if the inserted rule is a path that contains duplicated parameter names" do
      map = Marten::Routing::Map.new
      expect_raises(Marten::Routing::Errors::InvalidRulePath) do
        map.path("/path/xyz/<id:int>/test<id:slug>/bad", Marten::Views::Base, name: "home")
      end
    end

    it "raises if the inserted rule is a map that contains duplicated parameter names" do
      map = Marten::Routing::Map.new
      expect_raises(Marten::Routing::Errors::InvalidRulePath) do
        sub_map = Marten::Routing::Map.draw do
          path("/bad/<id:int>/foobar", Marten::Views::Base, name: "home")
        end
        map.path("/path/xyz/<id:int>", sub_map, name: "included")
      end
    end
  end
end
