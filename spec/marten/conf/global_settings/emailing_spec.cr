require "./spec_helper"

describe Marten::Conf::GlobalSettings::Emailing do
  describe "#backend" do
    it "returns the dev backend with emails printed disabled by default" do
      emailing_conf = Marten::Conf::GlobalSettings::Emailing.new

      emailing_conf.backend.should be_a Marten::Emailing::Backend::Development
      emailing_conf.backend.as(Marten::Emailing::Backend::Development).print_emails?.should be_false
    end

    it "returns the custom backend configured" do
      test_backend = Marten::Conf::GlobalSettings::EmailingSpec::TestBackend.new

      emailing_conf = Marten::Conf::GlobalSettings::Emailing.new
      emailing_conf.backend = test_backend

      emailing_conf.backend.should eq test_backend
    end
  end

  describe "#backend=" do
    it "allows to set the emailing backend" do
      test_backend = Marten::Conf::GlobalSettings::EmailingSpec::TestBackend.new

      emailing_conf = Marten::Conf::GlobalSettings::Emailing.new
      emailing_conf.backend = test_backend

      emailing_conf.backend.should eq test_backend
    end
  end

  describe "#from_address" do
    it "returns the expected email address by default" do
      emailing_conf = Marten::Conf::GlobalSettings::Emailing.new

      emailing_conf.from_address.should eq Marten::Emailing::Address.new("webmaster@localhost")
    end

    it "returns the configured email address" do
      emailing_conf = Marten::Conf::GlobalSettings::Emailing.new
      emailing_conf.from_address = "test@example.com"

      emailing_conf.from_address.should eq Marten::Emailing::Address.new("test@example.com")
    end
  end

  describe "#from_address=" do
    it "allows to the set the from address from a string" do
      emailing_conf = Marten::Conf::GlobalSettings::Emailing.new
      emailing_conf.from_address = "test@example.com"

      emailing_conf.from_address.should eq Marten::Emailing::Address.new("test@example.com")
    end

    it "allows to the set the from address from a symbol" do
      emailing_conf = Marten::Conf::GlobalSettings::Emailing.new
      emailing_conf.from_address = :"test@example.com"

      emailing_conf.from_address.should eq Marten::Emailing::Address.new("test@example.com")
    end

    it "allows to the set the from address from an address object" do
      emailing_conf = Marten::Conf::GlobalSettings::Emailing.new
      emailing_conf.from_address = Marten::Emailing::Address.new("test@example.com")

      emailing_conf.from_address.should eq Marten::Emailing::Address.new("test@example.com")
    end
  end
end

module Marten::Conf::GlobalSettings::EmailingSpec
  class TestBackend < Marten::Emailing::Backend::Base
    def deliver(email : Marten::Emailing::Email)
    end
  end
end
