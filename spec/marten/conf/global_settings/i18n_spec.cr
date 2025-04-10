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

  describe "#fallbacks" do
    it "returns the expected default value if not configured" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.fallbacks.default.should eq ["en"]
      i18n_conf.fallbacks.mapping.should be_empty
    end

    it "returns the expected value if explicitly configured" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.fallbacks = ["fr"]
      i18n_conf.fallbacks.default.should eq ["fr"]
      i18n_conf.fallbacks.mapping.should be_empty
    end
  end

  describe "#fallbacks=" do
    it "allows to configure the fallbacks using an array of strings" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.fallbacks = ["fr"]
      i18n_conf.fallbacks.default.should eq ["fr"]
      i18n_conf.fallbacks.mapping.should be_empty
    end

    it "allows to configure the fallbacks using an array of symbols" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.fallbacks = [:fr]
      i18n_conf.fallbacks.default.should eq ["fr"]
      i18n_conf.fallbacks.mapping.should be_empty
    end

    it "allows to configure the fallbacks using a hash of strings" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.fallbacks = {"fr" => ["en"]}
      i18n_conf.fallbacks.default.should be_empty
      i18n_conf.fallbacks.mapping.should eq({"fr" => ["en"]})
    end

    it "allows to configure the fallbacks using a hash of symbols" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.fallbacks = {:fr => [:en]}
      i18n_conf.fallbacks.default.should be_empty
      i18n_conf.fallbacks.mapping.should eq({"fr" => ["en"]})
    end

    it "allows to configure the fallbacks using a named tuple" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.fallbacks = {fr: ["en"]}
      i18n_conf.fallbacks.default.should be_empty
      i18n_conf.fallbacks.mapping.should eq({"fr" => ["en"]})
    end

    it "allows to configure the fallbacks using an I18n::Locale::Fallbacks instance" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.fallbacks = ::I18n::Locale::Fallbacks.new(default: ["en"], mapping: {"fr" => ["en"]})
      i18n_conf.fallbacks.default.should eq ["en"]
      i18n_conf.fallbacks.mapping.should eq({"fr" => ["en"]})
    end
  end

  describe "#locale_cookie_name" do
    it "returns the expected default value if not configured" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new

      i18n_conf.locale_cookie_name.should eq "marten_locale"
    end

    it "returns the configured locale cookie name" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.locale_cookie_name = "custom_locale"

      i18n_conf.locale_cookie_name.should eq "custom_locale"
    end
  end

  describe "#locale_cookie_name=" do
    it "allows to configure the locale cookie name using a string value" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.locale_cookie_name = "custom_locale"

      i18n_conf.locale_cookie_name.should eq "custom_locale"
    end

    it "allows to configure the locale cookie name using a symbol value" do
      i18n_conf = Marten::Conf::GlobalSettings::I18n.new
      i18n_conf.locale_cookie_name = :custom_locale

      i18n_conf.locale_cookie_name.should eq "custom_locale"
    end
  end
end
