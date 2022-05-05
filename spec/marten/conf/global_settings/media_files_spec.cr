require "./spec_helper"

describe Marten::Conf::GlobalSettings::MediaFiles do
  describe "#root" do
    it "returns media by default" do
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.root.should eq "media"
    end

    it "returns the configured root value" do
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.root = "files"
      media_conf.root.should eq "files"
    end
  end

  describe "#root=" do
    it "allows to configure the root dir from a string" do
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.root = "files"
      media_conf.root.should eq "files"
    end

    it "allows to configure the root dir from a symbol" do
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.root = :files
      media_conf.root.should eq "files"
    end

    it "allows to configure the root dire from a path" do
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.root = Path["files"]
      media_conf.root.should eq Path["files"].expand.to_s
    end
  end

  describe "#storage" do
    it "returns nil by default" do
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.storage.should be_nil
    end

    it "returns the configured storage if any" do
      storage = Marten::Core::Storage::FileSystem.new(root: "files", base_url: "/files/")
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.storage = storage
      media_conf.storage.should eq storage
    end
  end

  describe "#storage=" do
    it "can set the storage" do
      storage = Marten::Core::Storage::FileSystem.new(root: "files", base_url: "/files/")
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.storage = storage
      media_conf.storage.should eq storage
    end

    it "can reset the storage" do
      storage = Marten::Core::Storage::FileSystem.new(root: "files", base_url: "/files/")
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.storage = storage
      media_conf.storage = nil
      media_conf.storage.should be_nil
    end
  end

  describe "#url" do
    it "returns /media/ by default" do
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.url.should eq "/media/"
    end

    it "returns the configured url value" do
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.url = "/files/"
      media_conf.url.should eq "/files/"
    end
  end

  describe "#url=" do
    it "allows to set the media files URL from a string" do
      media_conf = Marten::Conf::GlobalSettings::MediaFiles.new
      media_conf.url = "/files/"
      media_conf.url.should eq "/files/"
    end
  end
end
