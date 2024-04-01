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

  describe "#setup_templates" do
    after_each do
      Marten.setup_templates
    end

    it "setup templates uses no loaders when `templates.loaders` setting is empty array" do
      with_overridden_setting("templates.loaders", [] of Marten::Template::Loader::Base, nilable: true) do
        Marten.setup_templates
        Marten.templates.loaders.size.should eq 0
      end
    end

    it "setup templates uses configured loaders" do
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

    it "setup templates uses default loaders when setting is nil" do
      with_overridden_setting("templates.loaders", nil, nilable: true) do
        Marten.setup_templates
        Marten.templates.loaders.size.should eq 2
      end
    end
  end
end
