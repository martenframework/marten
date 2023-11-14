require "./spec_helper"
require "./registry_spec/**"

describe Marten::Apps::Registry do
  describe "::new" do
    it "allows to initialize an apps registry" do
      registry = Marten::Apps::Registry.new
      registry.app_configs.should eq [] of Marten::Apps::Config
    end
  end

  describe "#app_configs" do
    it "returns the registered app config instances" do
      registry = Marten::Apps::Registry.new
      registry.populate([Marten::Apps::RegistrySpec::App])
      registry.app_configs.size.should eq 1
      registry.app_configs[0].should be_a Marten::Apps::RegistrySpec::App
    end
  end

  describe "#get" do
    it "returns the registered app corresponding to the passed app label string" do
      registry = Marten::Apps::Registry.new
      registry.populate([Marten::Apps::RegistrySpec::App])
      registry.get("test_a").should be_a Marten::Apps::RegistrySpec::App
    end

    it "returns the registered app corresponding to the passed app label symbol" do
      registry = Marten::Apps::Registry.new
      registry.populate([Marten::Apps::RegistrySpec::App])
      registry.get(:test_a).should be_a Marten::Apps::RegistrySpec::App
    end

    it "raises if the app label does not correspond to any registered apps" do
      registry = Marten::Apps::Registry.new
      expect_raises(
        Marten::Apps::Errors::AppNotFound,
        "Label 'unknown' is not associated with any installed apps"
      ) do
        registry.get("unknown")
      end
    end
  end

  describe "#populate" do
    it "allows to populate a list of registered app configs" do
      registry = Marten::Apps::Registry.new
      registry.populate([Marten::Apps::RegistrySpec::App, Marten::Apps::RegistrySpec::OtherApp::App])
      registry.app_configs.size.should eq 2
      registry.app_configs[0].should be_a Marten::Apps::RegistrySpec::App
      registry.app_configs[1].should be_a Marten::Apps::RegistrySpec::OtherApp::App
    end

    it "raises if the same app config is registered multiple times" do
      registry = Marten::Apps::Registry.new
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) do
        registry.populate(
          [
            Marten::Apps::RegistrySpec::App,
            Marten::Apps::RegistrySpec::OtherApp::App,
            Marten::Apps::RegistrySpec::App,
          ]
        )
      end
    end

    it "raises if the multiple app configs are registered with the same label" do
      registry = Marten::Apps::Registry.new
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) do
        registry.populate(
          [
            Marten::Apps::RegistrySpec::App,
            Marten::Apps::RegistrySpec::OtherApp::App,
            Marten::Apps::RegistrySpec::DupApp::App,
          ]
        )
      end
    end
  end

  describe "#get_containing" do
    it "returns the app config instance associated with the passed class" do
      registry = Marten::Apps::Registry.new
      registry.populate(
        [
          Marten::Apps::RegistrySpec::App,
          Marten::Apps::RegistrySpec::TestApp::App,
        ]
      )
      registry.get_containing(Marten::Apps::RegistrySpec::TestEntity).should(
        be_a(Marten::Apps::RegistrySpec::App)
      )
    end

    it "always picks the the app config corresponding to the deepest dir location" do
      registry = Marten::Apps::Registry.new
      registry.populate(
        [
          Marten::Apps::RegistrySpec::App,
          Marten::Apps::RegistrySpec::TestApp::App,
        ]
      )
      registry.get_containing(Marten::Apps::RegistrySpec::TestApp::Entities::Test).should(
        be_a(Marten::Apps::RegistrySpec::TestApp::App)
      )
    end

    it "raises if no app config for the given class can be found" do
      registry = Marten::Apps::Registry.new
      registry.populate(
        [
          Marten::Apps::RegistrySpec::App,
          Marten::Apps::RegistrySpec::TestApp::App,
        ]
      )
      expect_raises(
        Exception,
        "Class 'Marten::Apps::RegistrySpec::InvalidEntity' is not part of an application defined in " \
        "Marten.settings.installed_apps"
      ) do
        registry.get_containing(Marten::Apps::RegistrySpec::InvalidEntity)
      end
    end

    it "raises if the deepest app config that is found for the passed class is not installed" do
      registry = Marten::Apps::Registry.new
      registry.populate(
        [
          Marten::Apps::RegistrySpec::App,
        ]
      )

      expect_raises(
        Exception,
        "Class 'Marten::Apps::RegistrySpec::TestApp::Entities::Test' is not part of an application defined in " \
        "Marten.settings.installed_apps"
      ) do
        registry.get_containing(Marten::Apps::RegistrySpec::TestApp::Entities::Test)
      end
    end
  end

  describe "#insert_main_app" do
    it "inserts a main app config instance into the registry" do
      registry = Marten::Apps::Registry.new

      registry.insert_main_app

      registry.app_configs.size.should eq 1
      registry.app_configs[0].should be_a Marten::Apps::MainConfig
    end
  end

  describe "#main" do
    it "returns the main app config" do
      registry = Marten::Apps::Registry.new
      registry.insert_main_app

      registry.main.should be_a Marten::Apps::MainConfig
    end
  end
end

module Marten::Apps::RegistrySpec
  class InvalidEntity
    def self._marten_app_location
      "/etc/xyz"
    end
  end
end
