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
  end
end
