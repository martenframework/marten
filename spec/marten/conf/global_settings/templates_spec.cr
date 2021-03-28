require "./spec_helper"

describe Marten::Conf::GlobalSettings::Templates do
  describe "#app_dirs" do
    it "returns true by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.app_dirs.should be_true
    end

    it "returns true if configured accordingly" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.app_dirs = true
      templates_conf.app_dirs.should be_true
    end

    it "returns false if configured accordingly" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.app_dirs = false
      templates_conf.app_dirs.should be_false
    end
  end

  describe "#app_dirs=" do
    it "allows to change the app_dirs confiuration as expected" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new

      templates_conf.app_dirs = true
      templates_conf.app_dirs.should be_true

      templates_conf.app_dirs = false
      templates_conf.app_dirs.should be_false
    end
  end

  describe "#dirs" do
    it "returns an empty array of strings by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.dirs.should be_empty
    end

    it "returns the configured array of directories" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.dirs = [
        "src/path1/templates",
        "src/path2/templates",
      ]
      templates_conf.dirs.should eq([
        "src/path1/templates",
        "src/path2/templates",
      ])
    end
  end

  describe "#dirs=" do
    it "allows to set the array of templates directories as expected" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.dirs = [
        "src/path1/templates",
        "src/path2/templates",
      ]
      templates_conf.dirs.should eq([
        "src/path1/templates",
        "src/path2/templates",
      ])
    end
  end
end
