require "./spec_helper"
require "./config_spec/**"

describe Marten::Apps::Config do
  describe "::new" do
    it "allows to initialize an app config instance" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.label.should eq "test"
    end
  end

  describe "::label" do
    it "returns the configured app label" do
      Marten::Apps::ConfigSpec::TestConfig.label.should eq "test"
    end

    it "returns a default app label if not set" do
      Marten::Apps::ConfigSpec::DummyConfig.label.should eq "app"
    end
  end

  describe "::label(label)" do
    it "allows to configure an application label" do
      Marten::Apps::ConfigSpec::TestConfig.label("test123")
      Marten::Apps::ConfigSpec::TestConfig.label.should eq "test123"

      Marten::Apps::ConfigSpec::TestConfig.label("test_123")
      Marten::Apps::ConfigSpec::TestConfig.label.should eq "test_123"

      Marten::Apps::ConfigSpec::TestConfig.label("test")
      Marten::Apps::ConfigSpec::TestConfig.label.should eq "test"
    end

    it "raises if the passed app label is not a valid app label" do
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::ConfigSpec::DummyConfig.label("foo bar") }
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::ConfigSpec::DummyConfig.label("ABC") }
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::ConfigSpec::DummyConfig.label("123") }
    end

    it "raises if the passed app label is reserved" do
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::ConfigSpec::DummyConfig.label("main") }
    end
  end

  describe "::validate_label" do
    it "validates valid application labels" do
      Marten::Apps::ConfigSpec::TestConfig.validate_label("test123")
      Marten::Apps::ConfigSpec::TestConfig.validate_label("test_123")
      Marten::Apps::ConfigSpec::TestConfig.validate_label("test")
    end

    it "raises if the passed app label is not a valid app label" do
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) do
        Marten::Apps::ConfigSpec::DummyConfig.validate_label("foo bar")
      end

      expect_raises(Marten::Apps::Errors::InvalidAppConfig) do
        Marten::Apps::ConfigSpec::DummyConfig.validate_label("ABC")
      end

      expect_raises(Marten::Apps::Errors::InvalidAppConfig) do
        Marten::Apps::ConfigSpec::DummyConfig.validate_label("123")
      end
    end

    it "raises if the passed app label is reserved" do
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) do
        Marten::Apps::ConfigSpec::DummyConfig.validate_label("main")
      end
    end
  end

  describe "#==" do
    it "returns true if the other app config is the same object" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.should eq app_config
    end

    it "returns true if the other app config corresponds to the same app config" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.should eq Marten::Apps::ConfigSpec::TestConfig.new
    end

    it "returns false if the other app config does not correspond to the same app config" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.should_not eq Marten::Apps::ConfigSpec::DummyConfig.new
    end
  end

  describe "#assets_finder" do
    around_each do |t|
      FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")
      t.run
      FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")
    end

    it "returns an assets finder targetting the app assets folder" do
      app_config = Marten::Apps::ConfigSpec::AppWithAssets::App.new
      assets_finder = app_config.assets_finder
      assets_finder.should be_a Marten::Asset::Finder::FileSystem

      assets_finder.not_nil!.root.should eq Path[__DIR__].join("config_spec/app_with_assets/assets").to_s
    end

    it "takes into account the root path if one is configured" do
      FileUtils.ln_s(Path["."].expand.to_s, "/tmp/marten_spec")

      with_overridden_setting("root_path", "/tmp/marten_spec", nilable: true) do
        app_config = Marten::Apps::ConfigSpec::AppWithAssets::App.new
        assets_finder = app_config.assets_finder
        assets_finder.should be_a Marten::Asset::Finder::FileSystem

        assets_finder.not_nil!.root.should eq "/tmp/marten_spec/spec/marten/apps/config_spec/app_with_assets/assets"
      end
    end

    it "returns nil if the app does not define an assets directory" do
      app_config = Marten::Apps::ConfigSpec::AppWithoutAssets::App.new
      app_config.assets_finder.should be_nil
    end
  end

  describe "#label" do
    it "returns the app config label" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.label.should eq "test"
    end
  end

  describe "#main?" do
    it "returns false" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.main?.should be_false
    end
  end

  describe "#migrations_path" do
    it "returns the app config migrations path" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.migrations_path.should eq Path.new(__DIR__).join("migrations")
    end
  end

  describe "#models" do
    it "returns the app's list of models" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.register_model(Tag)
      app_config.models.should eq [Tag]
    end
  end

  describe "#register_model" do
    it "adds a model class to the app's list of models" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.register_model(Post)
      app_config.models.should eq [Post]
    end
  end

  describe "#templates_loader" do
    around_each do |t|
      FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")
      t.run
      FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")
    end

    it "returns a templates loader targetting the app templates" do
      app_config = Marten::Apps::ConfigSpec::AppWithTemplates::App.new
      templates_loader = app_config.templates_loader
      templates_loader.should be_a Marten::Template::Loader::FileSystem

      templates_loader.not_nil!.path.should eq Path[__DIR__].join("config_spec/app_with_templates/templates").to_s
    end

    it "takes into account the root path if one is configured" do
      FileUtils.ln_s(Path["."].expand.to_s, "/tmp/marten_spec")

      with_overridden_setting("root_path", "/tmp/marten_spec", nilable: true) do
        app_config = Marten::Apps::ConfigSpec::AppWithTemplates::App.new
        templates_loader = app_config.templates_loader
        templates_loader.should be_a Marten::Template::Loader::FileSystem

        templates_loader.not_nil!.path.should eq(
          "/tmp/marten_spec/spec/marten/apps/config_spec/app_with_templates/templates"
        )
      end
    end

    it "returns nil if the app does not define a templates directory" do
      app_config = Marten::Apps::ConfigSpec::AppWithoutTemplates::App.new
      app_config.templates_loader.should be_nil
    end
  end

  describe "#translations_loader" do
    around_each do |t|
      FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")
      t.run
      FileUtils.rm("/tmp/marten_spec") if File.exists?("/tmp/marten_spec")
    end

    it "returns a translations loader containing the app locales data" do
      app_config = Marten::Apps::ConfigSpec::AppWithTranslations::App.new
      translations_loader = app_config.translations_loader
      translations_loader.should be_a I18n::Loader::YAML

      translations_loader.not_nil!.load.should eq(
        I18n::TranslationsHash{
          "en" => I18n::TranslationsHash{
            "simple" => "Simple translation",
          },
        }
      )
    end

    it "takes into account the root path if one is configured" do
      FileUtils.ln_s(Path["."].expand.to_s, "/tmp/marten_spec")

      with_overridden_setting("root_path", "/tmp/marten_spec", nilable: true) do
        app_config = Marten::Apps::ConfigSpec::AppWithTranslations::App.new
        translations_loader = app_config.translations_loader
        translations_loader.should be_a I18n::Loader::YAML

        translations_loader.not_nil!.load.should eq(
          I18n::TranslationsHash{
            "en" => I18n::TranslationsHash{
              "simple" => "Simple translation",
            },
          }
        )
      end
    end

    it "returns nil if the app does not define locales data" do
      app_config = Marten::Apps::ConfigSpec::AppWithoutTranslations::App.new
      app_config.translations_loader.should be_nil
    end
  end
end

module Marten::Apps::ConfigSpec
  class TestConfig < Marten::App
    label :test
  end

  class DummyConfig < Marten::App
  end
end
