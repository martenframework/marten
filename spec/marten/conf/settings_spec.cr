require "./spec_helper"

describe Marten::Conf::Settings do
  describe "::namespace" do
    it "allows to attach a settings class to the global settings" do
      Marten.settings.custom1.should be_a Marten::Conf::SettingsSpec::CustomSettings1
      Marten.settings.custom1.foo.should eq "bar"
      Marten::Conf::GlobalSettings.settings_namespace_registered?("custom1").should be_true

      Marten.settings.custom2.should be_a Marten::Conf::SettingsSpec::CustomSettings2
      Marten::Conf::GlobalSettings.settings_namespace_registered?("custom2").should be_true
    end
  end
end

module Marten::Conf::SettingsSpec
  class CustomSettings1 < Marten::Conf::Settings
    namespace :custom1

    def initialize
      @foo = "bar"
    end

    def foo
      @foo
    end
  end

  class CustomSettings2 < Marten::Conf::Settings
    namespace :custom2

    def initialize
    end
  end
end
