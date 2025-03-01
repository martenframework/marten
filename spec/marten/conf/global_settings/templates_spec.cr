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

  describe "#app_dirs?" do
    it "returns true by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.app_dirs?.should be_true
    end

    it "returns true if configured accordingly" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.app_dirs = true
      templates_conf.app_dirs?.should be_true
    end

    it "returns false if configured accordingly" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.app_dirs = false
      templates_conf.app_dirs?.should be_false
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

  describe "#cached" do
    it "returns false by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.cached.should be_false
    end

    it "returns true if configured accordingly" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.cached = true
      templates_conf.cached.should be_true
    end

    it "returns false if configured accordingly" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.cached = false
      templates_conf.cached.should be_false
    end
  end

  describe "#cached?" do
    it "returns false by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.cached?.should be_false
    end

    it "returns true if configured accordingly" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.cached = true
      templates_conf.cached?.should be_true
    end

    it "returns false if configured accordingly" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.cached = false
      templates_conf.cached?.should be_false
    end
  end

  describe "#cached=" do
    it "allows to change the cached configuration as expected" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new

      templates_conf.cached = true
      templates_conf.cached.should be_true

      templates_conf.cached = false
      templates_conf.cached.should be_false
    end
  end

  describe "#context_producers" do
    it "returns an empty array by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.context_producers.should eq [] of Marten::Template::ContextProducer.class
    end

    it "returns the array configured context producers" do
      context_producers = [
        Marten::Template::ContextProducer::Debug,
        Marten::Template::ContextProducer::I18n,
      ]

      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.context_producers = context_producers

      templates_conf.context_producers.should eq context_producers
    end
  end

  describe "#context_producers=" do
    it "allows to configure the array of configured context producers" do
      context_producers = [
        Marten::Template::ContextProducer::Debug,
        Marten::Template::ContextProducer::I18n,
      ]

      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.context_producers = context_producers

      templates_conf.context_producers.should eq context_producers
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

    it "can allow to set the array of templates directories from symbols" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.dirs = [
        :"src/path1/templates",
        :"src/path2/templates",
      ]
      templates_conf.dirs.should eq([
        "src/path1/templates",
        "src/path2/templates",
      ])
    end

    it "can allow to set the array of templates directories from paths" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.dirs = [
        Path["src/path1/templates"],
        Path["src/path2/templates"],
      ]
      templates_conf.dirs.should eq([
        Path["src/path1/templates"].expand.to_s,
        Path["src/path2/templates"].expand.to_s,
      ])
    end
  end

  describe "#isolated_inclusions" do
    it "returns false by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new

      templates_conf.isolated_inclusions.should be_false
    end

    it "returns true if the isolated inclusions mode is enabled" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.isolated_inclusions = true

      templates_conf.isolated_inclusions.should be_true
    end
  end

  describe "#isolated_inclusions?" do
    it "returns false by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new

      templates_conf.isolated_inclusions?.should be_false
    end

    it "returns true if the isolated inclusions mode is enabled" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.isolated_inclusions = true

      templates_conf.isolated_inclusions?.should be_true
    end
  end

  describe "#loaders" do
    it "returns nil by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.loaders.should be_nil
    end

    it "returns the configured array of loaders" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      loaders = [
        Marten::Template::Loader::AppDirs.new,
        Marten::Template::Loader::FileSystem.new("/dummy/dir"),
      ]
      templates_conf.loaders = loaders
      templates_conf.loaders.should eq loaders
    end
  end

  describe "#loaders=" do
    it "allows to configure the array of configured context producers" do
      loaders = [
        Marten::Template::Loader::AppDirs.new,
        Marten::Template::Loader::FileSystem.new("/dummy/dir"),
      ]

      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.loaders = loaders

      templates_conf.loaders.should eq loaders
    end
  end

  describe "#isolated_inclusions=" do
    it "enables the isolated inclusions mode" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new

      templates_conf.isolated_inclusions = true

      templates_conf.isolated_inclusions?.should be_true
    end
  end

  describe "#strict_variables" do
    it "returns false by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new

      templates_conf.strict_variables.should be_false
    end

    it "returns true if the strict variables mode is enabled" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.strict_variables = true

      templates_conf.strict_variables.should be_true
    end
  end

  describe "#strict_variables?" do
    it "returns false by default" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new

      templates_conf.strict_variables?.should be_false
    end

    it "returns true if the strict variables mode is enabled" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new
      templates_conf.strict_variables = true

      templates_conf.strict_variables?.should be_true
    end
  end

  describe "#strict_variables=" do
    it "enables the strict variables mode" do
      templates_conf = Marten::Conf::GlobalSettings::Templates.new

      templates_conf.strict_variables = true

      templates_conf.strict_variables?.should be_true
    end
  end
end
