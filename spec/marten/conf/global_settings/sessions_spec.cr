require "./spec_helper"

describe Marten::Conf::GlobalSettings::Sessions do
  describe "#cookie_domain" do
    it "returns nil by default" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_domain.should be_nil
    end

    it "returns the configured value if applicable" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_domain = "example.com"
      sessions_conf.cookie_domain.should eq "example.com"
    end
  end

  describe "#cookie_domain=" do
    it "allows to configure the sessions cookie domain" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_domain = "example.com"
      sessions_conf.cookie_domain.should eq "example.com"
    end
  end

  describe "#cookie_http_only" do
    it "returns false by default" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_http_only.should be_false
    end

    it "returns the configured value if applicable" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_http_only = true
      sessions_conf.cookie_http_only.should be_true
    end
  end

  describe "#cookie_http_only=" do
    it "allows to configure that client-side JS scripts should not have access to the session cookie" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_http_only = true
      sessions_conf.cookie_http_only.should be_true
    end
  end

  describe "#cookie_max_age" do
    it "returns two weeks by default" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_max_age.should eq 1_209_600
    end

    it "returns the configured value if applicable" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_max_age = 42
      sessions_conf.cookie_max_age.should eq 42
    end
  end

  describe "#cookie_max_age=" do
    it "allows to configure the cookie max age" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_max_age = 42
      sessions_conf.cookie_max_age.should eq 42
    end
  end

  describe "#cookie_name" do
    it "returns sessionid by default" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_name.should eq "sessionid"
    end

    it "returns the configured value if applicable" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_name = "custom_name"
      sessions_conf.cookie_name.should eq "custom_name"
    end
  end

  describe "#cookie_name=" do
    it "allows to configure the cookie name from a string" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_name = "custom_name"
      sessions_conf.cookie_name.should eq "custom_name"
    end

    it "allows to configure the cookie name from a symbol" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_name = :custom_name
      sessions_conf.cookie_name.should eq "custom_name"
    end
  end

  describe "#cookie_same_site" do
    it "returns Lax by default" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_same_site.should eq "Lax"
    end

    it "returns the configured value if applicable" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_same_site = "Strict"
      sessions_conf.cookie_same_site.should eq "Strict"
    end
  end

  describe "#cookie_same_site=" do
    it "allows to configure the cookie same site policy" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_same_site = "Strict"
      sessions_conf.cookie_same_site.should eq "Strict"
    end
  end

  describe "#cookie_secure" do
    it "returns false by default" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_secure.should be_false
    end

    it "returns the configured value if applicable" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_secure = true
      sessions_conf.cookie_secure.should be_true
    end
  end

  describe "#cookie_secure=" do
    it "allows to configure whether a secure cookie should be used" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.cookie_secure = true
      sessions_conf.cookie_secure.should be_true
    end
  end

  describe "#store" do
    it "returns cookie by default" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.store.should eq "cookie"
    end

    it "returns the configured value if applicable" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.store = "other"
      sessions_conf.store.should eq "other"
    end
  end

  describe "#store=" do
    it "allows to configure the store from a string" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.store = "other_store"
      sessions_conf.store.should eq "other_store"
    end

    it "allows to configure the cookie name from a symbol" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.store = :other_store
      sessions_conf.store.should eq "other_store"
    end
  end

  describe "#validate" do
    it "does not raise anything by default" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.validate.should be_nil
    end

    it "raises as expected if the configured store does not exist" do
      sessions_conf = Marten::Conf::GlobalSettings::Sessions.new
      sessions_conf.store = :unknown_store

      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        "Unknown session store 'unknown_store'"
      ) do
        sessions_conf.validate
      end
    end
  end
end
