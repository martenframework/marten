require "./spec_helper"

describe Marten::Asset::Engine do
  describe "#find" do
    it "returns the absolute path corresponding to a specific asset file path" do
      engine = Marten::Asset::Engine.new(
        storage: Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      )

      engine.finders << Marten::Asset::Finder::AppDirs.new
      engine.finders << Marten::Asset::Finder::FileSystem.new(File.join(__DIR__, "finder/assets"))

      engine.find("test.css").should eq File.join(TestApp.new.assets_finder.not_nil!.root, "test.css")
      engine.find("css/test.css").should eq File.join(TestApp.new.assets_finder.not_nil!.root, "css/test.css")
      engine.find("css/other.css").should eq File.join(__DIR__, "finder/assets/css/other.css")
    end

    it "raises if no asset corresponds to the passed file name" do
      engine = Marten::Asset::Engine.new(
        storage: Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      )

      engine.finders << Marten::Asset::Finder::AppDirs.new
      engine.finders << Marten::Asset::Finder::FileSystem.new(File.join(__DIR__, "finder/assets"))

      expect_raises(Marten::Asset::Errors::AssetNotFound) do
        engine.find("css/unknown.css")
      end
    end
  end

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

  describe "#url" do
    it "returns the storage URL by default if no manifests are configured" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      engine = Marten::Asset::Engine.new(storage: storage)
      engine.url("css/app.css").should eq "/assets/css/app.css"
    end

    it "returns the storage URL computed using the file name retrieved from the manifest if applicable" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")

      engine = Marten::Asset::Engine.new(storage: storage)
      engine.manifests << File.join(__DIR__, "engine_spec/manifest.json")

      engine.url("css/app.css").should eq "/assets/css/app.12345.css"
    end

    it "uses the passed file path as is if a manifest is configured but it does not contain the file path" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")

      engine = Marten::Asset::Engine.new(storage: storage)
      engine.manifests << File.join(__DIR__, "engine_spec/manifest.json")

      engine.url("css/other.css").should eq "/assets/css/other.css"
    end
  end
end

module Marten::Asset::EngineSpec
  class TestFinder < Marten::Asset::Finder::Base
    def find(filepath : String) : String
      ""
    end

    def list : Array({String, String})
      [] of {String, String}
    end
  end
end
