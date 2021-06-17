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
      Marten::Apps::ConfigSpec::TestConfig.label.should eq "test"
    end

    it "raises if the passed app label is not a valid app label" do
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::ConfigSpec::DummyConfig.label("foo bar") }
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::ConfigSpec::DummyConfig.label("ABC") }
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::ConfigSpec::DummyConfig.label("123") }
    end
  end

  describe "#label" do
    it "returns the app config label" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.label.should eq "test"
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
    it "returns a templates loader targetting the app templates" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      templates_loader = app_config.templates_loader
      templates_loader.should be_a Marten::Template::Loader::FileSystem

      templates_loader.not_nil!.path.should eq Path[__DIR__].join("templates").to_s
    end

    it "returns nil if the app does not define a templates directory" do
      app_config = Marten::Apps::ConfigSpec::AppWithoutTemplates::App.new
      app_config.templates_loader.should be_nil
    end
  end

  describe "#translations_loader" do
    it "returns a translations loader containing the app locales data" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
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
