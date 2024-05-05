require "./spec_helper"

describe Marten do
  describe "#assets" do
    it "returns the assets engine" do
      Marten.assets.should be_a Marten::Asset::Engine
    end
  end

  describe "#cache" do
    it "returns the configured cache store" do
      Marten.cache.should eq Marten.settings.cache_store
    end
  end

  describe "#setup" do
    context "with root path" do
      around_each do |t|
        FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")

        with_overridden_setting("root_path", "/tmp/marten_spec", nilable: true) do
          t.run
        end

        FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")
      end

      it "properly loads Marten built-in locales" do
        I18n.t("marten.db.field.base.errors.blank").should eq "This field cannot be blank."
      end
    end
  end

  describe "#setup_assets" do
    after_each do
      Marten.setup_assets
    end

    it "ensures custom asset dirs have priority over app dirs" do
      with_overridden_setting("assets.dirs", ["foo/bar"]) do
        with_overridden_setting("assets.app_dirs", true) do
          Marten.setup_assets
          Marten.assets.finders[0].should be_a Marten::Asset::Finder::FileSystem
          Marten.assets.finders[1].should be_a Marten::Asset::Finder::AppDirs
        end
      end
    end
  end

  describe "#setup_templates" do
    after_each do
      Marten.setup_templates
    end

    it "uses no loaders when `templates.loaders` setting is empty array" do
      with_overridden_setting("templates.loaders", [] of Marten::Template::Loader::Base, nilable: true) do
        Marten.setup_templates
        Marten.templates.loaders.size.should eq 0
      end
    end

    it "uses the configured loaders" do
      file_system_loader = Marten::Template::Loader::FileSystem.new("/root/templates")
      with_overridden_setting(
        "templates.loaders",
        [file_system_loader] of Marten::Template::Loader::Base,
        nilable: true
      ) do
        Marten.setup_templates
        Marten.templates.loaders.size.should eq 1
        Marten.templates.loaders[0].should eq file_system_loader
      end
    end

    it "uses default loaders when the `templates.loaders` setting is set to nil" do
      with_overridden_setting("templates.loaders", nil, nilable: true) do
        Marten.setup_templates
        Marten.templates.loaders.size.should eq 2
      end
    end
  end
end
