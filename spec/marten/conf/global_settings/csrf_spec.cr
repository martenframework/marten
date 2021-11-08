require "./spec_helper"

describe Marten::Conf::GlobalSettings::CSRF do
  describe "#cookie_domain" do
    it "returns nil by default" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_domain.should be_nil
    end

    it "returns the configured value if applicable" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_domain = "example.com"
      csrf_conf.cookie_domain.should eq "example.com"
    end
  end

  describe "#cookie_domain=" do
    it "allows to configure the CSRF cookie domain" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_domain = "example.com"
      csrf_conf.cookie_domain.should eq "example.com"
    end
  end

  describe "#cookie_http_only" do
    it "returns false by default" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_http_only.should be_false
    end

    it "returns the configured value if applicable" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_http_only = true
      csrf_conf.cookie_http_only.should be_true
    end
  end

  describe "#cookie_http_only=" do
    it "allows to configure that client-side JS scripts should not have access to the CSRF cookie" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_http_only = true
      csrf_conf.cookie_http_only.should be_true
    end
  end

  describe "#cookie_max_age" do
    it "returns one year by default" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_max_age.should eq 31_556_952
    end

    it "returns the configured value if applicable" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_max_age = 42
      csrf_conf.cookie_max_age.should eq 42
    end
  end

  describe "#cookie_max_age=" do
    it "allows to configure the cookie max age" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_max_age = 42
      csrf_conf.cookie_max_age.should eq 42
    end
  end

  describe "#cookie_name" do
    it "returns csrftoken by default" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_name.should eq "csrftoken"
    end

    it "returns the configured value if applicable" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_name = "custom_name"
      csrf_conf.cookie_name.should eq "custom_name"
    end
  end

  describe "#cookie_name=" do
    it "allows to configure the cookie name from a string" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_name = "custom_name"
      csrf_conf.cookie_name.should eq "custom_name"
    end

    it "allows to configure the cookie name from a symbol" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_name = :custom_name
      csrf_conf.cookie_name.should eq "custom_name"
    end
  end

  describe "#cookie_same_site" do
    it "returns Lax by default" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_same_site.should eq "Lax"
    end

    it "returns the configured value if applicable" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_same_site = "Strict"
      csrf_conf.cookie_same_site.should eq "Strict"
    end
  end

  describe "#cookie_same_site=" do
    it "allows to configure the cookie same site policy" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_same_site = "Strict"
      csrf_conf.cookie_same_site.should eq "Strict"
    end
  end

  describe "#cookie_secure" do
    it "returns false by default" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_secure.should be_false
    end

    it "returns the configured value if applicable" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_secure = true
      csrf_conf.cookie_secure.should be_true
    end
  end

  describe "#cookie_secure=" do
    it "allows to configure whether a secure cookie should be used" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.cookie_secure = true
      csrf_conf.cookie_secure.should be_true
    end
  end

  describe "#protection_enabled" do
    it "returns true by default" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.protection_enabled.should be_true
    end

    it "returns the configured value if applicable" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.protection_enabled = false
      csrf_conf.protection_enabled.should be_false
    end
  end

  describe "#protection_enabled=" do
    it "allows to disable the CSRF protection" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.protection_enabled = false
      csrf_conf.protection_enabled.should be_false
    end
  end

  describe "#trusted_origins" do
    it "returns an empty array by default" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.trusted_origins.should be_empty
    end

    it "returns the configured value if applicable" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.trusted_origins = ["https://*.example.com"]
      csrf_conf.trusted_origins.should eq ["https://*.example.com"]
    end
  end

  describe "#trusted_origins=" do
    it "allows to configure the array of trusted origins" do
      csrf_conf = Marten::Conf::GlobalSettings::CSRF.new
      csrf_conf.trusted_origins = ["https://*.example.com"]
      csrf_conf.trusted_origins.should eq ["https://*.example.com"]
    end
  end
end
