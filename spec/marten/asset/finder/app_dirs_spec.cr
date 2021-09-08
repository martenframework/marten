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

    it "raises if no asset corresponds to the passed file name" do
      finder = Marten::Asset::Finder::AppDirs.new
      expect_raises(Marten::Asset::Errors::AssetNotFound) do
        finder.find("css/unknown.css")
      end
    end
  end

  describe "#list" do
    it "lists the relative and absolute paths of all the app assets" do
      finder = Marten::Asset::Finder::AppDirs.new
      finder.list.to_set.should eq(
        [
          {"test.css", File.join(TestApp.new.assets_finder.not_nil!.root, "test.css")},
          {"css/test.css", File.join(TestApp.new.assets_finder.not_nil!.root, "css/test.css")},
          {"unidentified_file", File.join(TestApp.new.assets_finder.not_nil!.root, "unidentified_file")},
        ].to_set
      )
    end
  end
end
