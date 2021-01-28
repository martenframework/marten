require "./spec_helper"

describe Marten::Conf::GlobalSettings::I18n do
  describe "#available_locales=" do
    it "allows to set the available locales from an array of symbols" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.available_locales = [:en, :fr]
      i18n_conf.available_locales.should eq ["en", "fr"]
    end

    it "allows to set the available locales from an array of strings" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.available_locales = ["en", "fr"]
      i18n_conf.available_locales.should eq ["en", "fr"]
    end

    it "allows to reset the available locales using nil" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.available_locales = nil
      i18n_conf.available_locales.should be_nil
    end
  end

  describe "#default_locale=" do
    it "allows to set the default locale using a symbol" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.default_locale = :fr
      i18n_conf.default_locale.should eq "fr"
    end

    it "allows to set the default locale using a string" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.default_locale = "fr"
      i18n_conf.default_locale.should eq "fr"
    end
  end
end
