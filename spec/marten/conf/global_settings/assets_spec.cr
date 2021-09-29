require "./spec_helper"

describe Marten::Conf::GlobalSettings::Assets do
  describe "#app_dirs" do
    it "returns true by default" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.app_dirs.should be_true
    end

    it "returns true if configured accordingly" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.app_dirs = true
      assets_conf.app_dirs.should be_true
    end

    it "returns false if configured accordingly" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.app_dirs = false
      assets_conf.app_dirs.should be_false
    end
  end

  describe "#app_dirs=" do
    it "allows to change the app_dirs confiuration as expected" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new

      assets_conf.app_dirs = true
      assets_conf.app_dirs.should be_true

      assets_conf.app_dirs = false
      assets_conf.app_dirs.should be_false
    end
  end

  describe "#dirs" do
    it "returns an empty array of strings by default" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.dirs.should be_empty
    end

    it "returns the configured array of directories" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.dirs = [
        "src/path1/assets",
        "src/path2/assets",
      ]
      assets_conf.dirs.should eq([
        "src/path1/assets",
        "src/path2/assets",
      ])
    end
  end

  describe "#dirs=" do
    it "allows to set the array of assets directories as expected" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.dirs = [
        "src/path1/assets",
        "src/path2/assets",
      ]
      assets_conf.dirs.should eq([
        "src/path1/assets",
        "src/path2/assets",
      ])
    end

    it "can allow to set the array of assets directories from symbols" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.dirs = [
        :"src/path1/assets",
        :"src/path2/assets",
      ]
      assets_conf.dirs.should eq([
        "src/path1/assets",
        "src/path2/assets",
      ])
    end

    it "can allow to set the array of assets directories from paths" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.dirs = [
        Path["src/path1/assets"],
        Path["src/path2/assets"],
      ]
      assets_conf.dirs.should eq([
        Path["src/path1/assets"].expand.to_s,
        Path["src/path2/assets"].expand.to_s,
      ])
    end
  end

  describe "#manifests" do
    it "returns an empty array of strings by default" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.manifests.should be_empty
    end

    it "returns the configured array of manifest file paths" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.manifests = [
        "src/path1/manifest1.json",
        "src/path1/manifest2.json",
      ]
      assets_conf.manifests.should eq([
        "src/path1/manifest1.json",
        "src/path1/manifest2.json",
      ])
    end
  end

  describe "#manifests=" do
    it "allows to set the array of manifest files to load" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.manifests = [
        "src/path1/manifest1.json",
        "src/path1/manifest2.json",
      ]
      assets_conf.manifests.should eq([
        "src/path1/manifest1.json",
        "src/path1/manifest2.json",
      ])
    end

    it "can allow to set the array of manifest files from symbols" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.manifests = [
        :"src/path1/manifest1.json",
        :"src/path1/manifest2.json",
      ]
      assets_conf.manifests.should eq([
        "src/path1/manifest1.json",
        "src/path1/manifest2.json",
      ])
    end

    it "can allow to set the array of manifest files from path objects" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.manifests = [
        Path["src/path1/manifest1.json"],
        Path["src/path1/manifest2.json"],
      ]
      assets_conf.manifests.should eq([
        Path["src/path1/manifest1.json"].expand.to_s,
        Path["src/path1/manifest2.json"].expand.to_s,
      ])
    end
  end

  describe "#root" do
    it "returns the expected default value by default" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.root.should eq "assets"
    end

    it "returns the configured value if applicable" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.root = "path/to/assets"
      assets_conf.root.should eq "path/to/assets"
    end
  end

  describe "#root=" do
    it "allows to set the assets root" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.root = "path/to/assets"
      assets_conf.root.should eq "path/to/assets"
    end
  end

  describe "#storage" do
    it "returns nil by default" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.storage.should be_nil
    end

    it "returns the configured storage if applicable" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.storage = storage
      assets_conf.storage.should eq storage
    end
  end

  describe "#storage=" do
    it "allows to configure the assets storage" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.storage = storage
      assets_conf.storage.should eq storage
    end

    it "can reset the assets storage" do
      storage = Marten::Core::Storage::FileSystem.new(root: "assets", base_url: "/assets/")
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.storage = storage
      assets_conf.storage = nil
      assets_conf.storage.should be_nil
    end
  end

  describe "#url" do
    it "returns the expected default value by default" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.url.should eq "/assets/"
    end

    it "returns the configured value if applicable" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.url = "/assets/url/"
      assets_conf.url.should eq "/assets/url/"
    end
  end

  describe "#url=" do
    it "allows to set the assets URL" do
      assets_conf = Marten::Conf::GlobalSettings::Assets.new
      assets_conf.url = "/assets/url/"
      assets_conf.url.should eq "/assets/url/"
    end
  end
end
