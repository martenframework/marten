require "./spec_helper"

describe Marten::Apps::MainConfig do
  describe "::_marten_app_location" do
    it "returns the relative src folder path" do
      Marten::Apps::MainConfig._marten_app_location.should eq Path["src"].expand.to_s
    end
  end

  describe "::label" do
    it "returns the expected reserved label" do
      Marten::Apps::MainConfig.label.should eq "main"
    end

    it "returns the configured label if one is set explicitly" do
      Marten::Apps::MainConfig.label("test")
      Marten::Apps::MainConfig.label.should eq "test"
    ensure
      Marten::Apps::MainConfig.label(Marten::Apps::MainConfig::DEFAULT_LABEL)
    end
  end

  describe "::validate_label" do
    it "allows blank labels" do
      Marten::Apps::MainConfig.validate_label("").should be_nil
    end

    it "does not allow invalid labels" do
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::MainConfig.validate_label("foo bar") }
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::MainConfig.validate_label("ABC") }
      expect_raises(Marten::Apps::Errors::InvalidAppConfig) { Marten::Apps::MainConfig.validate_label("123") }
    end
  end

  describe "#main?" do
    it "returns true" do
      app_config = Marten::Apps::MainConfig.new
      app_config.main?.should be_true
    end
  end
end
