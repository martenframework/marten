require "./spec_helper"

describe Marten::Conf::GlobalSettings::SSLRedirect do
  describe "#exempted_paths" do
    it "is empty by default" do
      ssl_redirect_conf = Marten::Conf::GlobalSettings::SSLRedirect.new

      ssl_redirect_conf.exempted_paths.should be_empty
    end

    it "returns the configured exempted paths" do
      ssl_redirect_conf = Marten::Conf::GlobalSettings::SSLRedirect.new
      ssl_redirect_conf.exempted_paths = ["/foo/bar", /^no-ssl\/$/]

      ssl_redirect_conf.exempted_paths.should eq ["/foo/bar", /^no-ssl\/$/]
    end
  end

  describe "#exempted_paths=" do
    it "allows to set the exempted paths" do
      ssl_redirect_conf = Marten::Conf::GlobalSettings::SSLRedirect.new

      ssl_redirect_conf.exempted_paths = ["/foo/bar", /^no-ssl\/$/]

      ssl_redirect_conf.exempted_paths.should eq ["/foo/bar", /^no-ssl\/$/]
    end
  end

  describe "#host" do
    it "returns nil by default" do
      ssl_redirect_conf = Marten::Conf::GlobalSettings::SSLRedirect.new

      ssl_redirect_conf.host.should be_nil
    end

    it "returns the configured host" do
      ssl_redirect_conf = Marten::Conf::GlobalSettings::SSLRedirect.new
      ssl_redirect_conf.host = "example.com"

      ssl_redirect_conf.host.should eq "example.com"
    end
  end

  describe "#host=" do
    it "allows to set the SSl redirect host" do
      ssl_redirect_conf = Marten::Conf::GlobalSettings::SSLRedirect.new

      ssl_redirect_conf.host = "example.com"

      ssl_redirect_conf.host.should eq "example.com"
    end
  end
end
