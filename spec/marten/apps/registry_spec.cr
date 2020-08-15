require "./registry_spec/**"
require "./spec_helper"

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
      registry.populate([Marten::Apps::RegistrySpec::Test1Config])
      registry.app_configs.size.should eq 1
      registry.app_configs[0].should be_a Marten::Apps::RegistrySpec::Test1Config
    end
  end

  describe "#populate" do
    it "allows to populate a list of registered app configs" do
      registry = Marten::Apps::Registry.new
      registry.populate([Marten::Apps::RegistrySpec::Test1Config, Marten::Apps::RegistrySpec::Test2Config])
      registry.app_configs.size.should eq 2
      registry.app_configs[0].should be_a Marten::Apps::RegistrySpec::Test1Config
      registry.app_configs[1].should be_a Marten::Apps::RegistrySpec::Test2Config
    end

    it "raises if the same app config is registered multiple times" do
      registry = Marten::Apps::Registry.new
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) do
        registry.populate(
          [
            Marten::Apps::RegistrySpec::Test1Config,
            Marten::Apps::RegistrySpec::Test2Config,
            Marten::Apps::RegistrySpec::Test1Config,
          ]
        )
      end
    end

    it "raises if the multiple app configs are registered with the same label" do
      registry = Marten::Apps::Registry.new
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) do
        registry.populate(
          [
            Marten::Apps::RegistrySpec::Test1Config,
            Marten::Apps::RegistrySpec::Test2Config,
            Marten::Apps::RegistrySpec::DupTest1Config,
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
          Marten::Apps::RegistrySpec::Test1Config,
          Marten::Apps::RegistrySpec::TestApp::App,
        ]
      )
      registry.get_containing(Marten::Apps::RegistrySpec::TestEntity).should(
        be_a(Marten::Apps::RegistrySpec::Test1Config)
      )
    end

    it "always picks the the app config corresponding to the deepest dir location" do
      registry = Marten::Apps::Registry.new
      registry.populate(
        [
          Marten::Apps::RegistrySpec::Test1Config,
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
          Marten::Apps::RegistrySpec::Test1Config,
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
  end
end

module Marten::Apps::RegistrySpec
  class Test1Config < Marten::Apps::Config
    label :test_a
  end

  class DupTest1Config < Marten::Apps::Config
    label :test_a
  end

  class Test2Config < Marten::Apps::Config
    label :test_b
  end

  class TestEntity
    def self.dir_location
      __DIR__
    end
  end

  class InvalidEntity
    def self.dir_location
      "/etc/xyz"
    end
  end
end
