require "./spec_helper"

describe Marten::Asset::Engine do
  describe "#finders" do
    it "returns the engine finders" do
      engine = Marten::Asset::Engine.new(
        storage: Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      )

      finder = Marten::Asset::EngineSpec::TestFinder.new
      engine.finders << finder

      engine.finders.should eq [finder]
    end
  end

  describe "#finders=" do
    it "allows to set the engine finders" do
      engine = Marten::Asset::Engine.new(
        storage: Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      )

      finder = Marten::Asset::EngineSpec::TestFinder.new
      engine.finders = [finder] of Marten::Asset::Finder::Base

      engine.finders.should eq [finder]
    end
  end

  describe "#storage" do
    it "returns the associated storage" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      engine = Marten::Asset::Engine.new(storage: storage)
      engine.storage.should eq storage
    end
  end
end

module Marten::Asset::EngineSpec
  class TestFinder < Marten::Asset::Finder::Base
    def find(filepath : String) : String
      ""
    end

    def list : Array(String)
      [] of String
    end
  end
end
