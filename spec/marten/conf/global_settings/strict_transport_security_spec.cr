require "./spec_helper"

describe Marten::Conf::GlobalSettings::StrictTransportSecurity do
  describe "#include_sub_domains" do
    it "returns false by default" do
      sts_config = Marten::Conf::GlobalSettings::StrictTransportSecurity.new
      sts_config.include_sub_domains.should be_false
    end

    it "returns the customized value if applicable" do
      sts_config = Marten::Conf::GlobalSettings::StrictTransportSecurity.new
      sts_config.include_sub_domains = true
      sts_config.include_sub_domains.should be_true
    end
  end

  describe "#include_sub_domains=" do
    it "allows to specify a custom setting value as expected" do
      sts_config = Marten::Conf::GlobalSettings::StrictTransportSecurity.new
      sts_config.include_sub_domains = true
      sts_config.include_sub_domains.should be_true
    end
  end

  describe "#max_age" do
    it "returns nil by default" do
      sts_config = Marten::Conf::GlobalSettings::StrictTransportSecurity.new
      sts_config.max_age.should be_nil
    end

    it "returns the customized value if applicable" do
      sts_config = Marten::Conf::GlobalSettings::StrictTransportSecurity.new
      sts_config.max_age = 3_600
      sts_config.max_age.should eq 3_600
    end
  end

  describe "#max_age=" do
    it "allows to specify a custom setting value as expected" do
      sts_config = Marten::Conf::GlobalSettings::StrictTransportSecurity.new
      sts_config.max_age = 3_600
      sts_config.max_age.should eq 3_600
    end
  end

  describe "#preload" do
    it "returns false by default" do
      sts_config = Marten::Conf::GlobalSettings::StrictTransportSecurity.new
      sts_config.preload.should be_false
    end

    it "returns the customized value if applicable" do
      sts_config = Marten::Conf::GlobalSettings::StrictTransportSecurity.new
      sts_config.preload = true
      sts_config.preload.should be_true
    end
  end

  describe "#preload=" do
    it "allows to specify a custom setting value as expected" do
      sts_config = Marten::Conf::GlobalSettings::StrictTransportSecurity.new
      sts_config.preload = true
      sts_config.preload.should be_true
    end
  end
end
