require "./spec_helper"

describe Marten::Asset::Finder::FileSystem do
  describe "#find" do
    it "returns the absolute path towards the passed asset file name" do
      finder = Marten::Asset::Finder::FileSystem.new(File.join(__DIR__, "assets"))
      finder.find("test.css").should eq File.join(__DIR__, "assets/test.css")
    end

    it "returns the absolute path towards the passed asset file filepath" do
      finder = Marten::Asset::Finder::FileSystem.new(File.join(__DIR__, "assets"))
      finder.find("css/test.css").should eq File.join(__DIR__, "assets/css/test.css")
    end

    it "raises if no asset corresponds to the passed file name" do
      finder = Marten::Asset::Finder::FileSystem.new(File.join(__DIR__, "assets"))
      expect_raises(Marten::Asset::Errors::AssetNotFound) do
        finder.find("css/unknown.css")
      end
    end
  end

  describe "#list" do
    it "returns the absolute paths of all the underlying assets" do
      finder = Marten::Asset::Finder::FileSystem.new(File.join(__DIR__, "assets"))
      finder.list.to_set.should eq(
        [
          {"test.css", File.join(__DIR__, "assets/test.css")},
          {"css/other.css", File.join(__DIR__, "assets/css/other.css")},
          {"css/test.css", File.join(__DIR__, "assets/css/test.css")},
        ].to_set
      )
    end
  end
end
