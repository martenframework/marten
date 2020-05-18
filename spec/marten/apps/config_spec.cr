require "./spec_helper"

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

  describe "::dir_location" do
    it "returns the path where the app config class is defined" do
      Marten::Apps::ConfigSpec::TestConfig.dir_location.should eq __DIR__
    end
  end

  describe "#label" do
    it "returns the app config label" do
      app_config = Marten::Apps::ConfigSpec::TestConfig.new
      app_config.label.should eq "test"
    end
  end
end

module Marten::Apps::ConfigSpec
  class TestConfig < Marten::Apps::Config
    label :test
  end

  class DummyConfig < Marten::Apps::Config
  end
end
