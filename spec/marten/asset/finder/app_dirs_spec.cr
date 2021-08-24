require "./spec_helper"

describe Marten::Asset::Finder::AppDirs do
  describe "#find" do
    it "returns the absolute path towards the passed asset file name" do
      finder = Marten::Asset::Finder::AppDirs.new
      finder.find("test.css").should eq File.join(TestApp.new.assets_finder.not_nil!.root, "test.css")
    end

    it "returns the absolute path towards the passed asset file filepath" do
      finder = Marten::Asset::Finder::AppDirs.new
      finder.find("css/test.css").should eq File.join(TestApp.new.assets_finder.not_nil!.root, "css/test.css")
    end

    it "returns nil if no asset corresponds to the passed file name" do
      finder = Marten::Asset::Finder::AppDirs.new
      finder.find("css/unknown.css").should be_nil
    end
  end

  describe "#list" do
    it "lists the absolute paths of all the app assets" do
      finder = Marten::Asset::Finder::AppDirs.new
      finder.list.to_set.should eq(
        [
          File.join(TestApp.new.assets_finder.not_nil!.root, "test.css"),
          File.join(TestApp.new.assets_finder.not_nil!.root, "css/test.css"),
        ].to_set
      )
    end
  end
end
