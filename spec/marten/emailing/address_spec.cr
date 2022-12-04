require "./spec_helper"

describe Marten::Emailing::Address do
  describe "#==" do
    it "returns true if the two addresses are the same object" do
      email_address = Marten::Emailing::Address.new("test@example.com")
      email_address.should eq email_address
    end

    it "returns true if the two addresses have the same part values" do
      email_address_without_name = Marten::Emailing::Address.new("test@example.com")
      email_address_without_name.should eq Marten::Emailing::Address.new("test@example.com")

      email_address_with_name = Marten::Emailing::Address.new("test@example.com", "John Doe")
      email_address_with_name.should eq Marten::Emailing::Address.new("test@example.com", "John Doe")
    end

    it "returns false if the two addresses do not have the same part values" do
      email_address_without_name = Marten::Emailing::Address.new("test@example.com")
      email_address_without_name.should_not eq Marten::Emailing::Address.new("other@example.com")

      email_address_with_name = Marten::Emailing::Address.new("test@example.com", "John Doe")
      email_address_with_name.should_not eq Marten::Emailing::Address.new("test@example.com", "Other")
    end
  end

  describe "#address" do
    it "returns the raw email address" do
      email_address = Marten::Emailing::Address.new("test@example.com")
      email_address.address.should eq "test@example.com"
    end
  end

  describe "#name" do
    it "returns nil if the email address does not have a name part" do
      email_address = Marten::Emailing::Address.new("test@example.com")
      email_address.name.should be_nil
    end

    it "returns the name part of the email address" do
      email_address = Marten::Emailing::Address.new("test@example.com", "John Doe")
      email_address.name.should eq "John Doe"
    end
  end

  describe "#to_s" do
    it "produces the expected output for an email address without a name part" do
      email_address = Marten::Emailing::Address.new("test@example.com")
      email_address.to_s.should eq "test@example.com"
    end

    it "produces the expected output for an email address with a name part" do
      email_address = Marten::Emailing::Address.new("test@example.com", "John Doe")
      email_address.to_s.should eq %{"John Doe" <test@example.com>}
    end
  end
end
