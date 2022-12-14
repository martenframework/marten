require "./spec_helper"

describe Marten::Emailing::Address do
  describe "::valid?" do
    it "returns true for valid email addresses" do
      {
        "test@example.com",
        "test@[127.0.0.1]",
        "test@[2001:dB8::1]",
        "test@[2001:dB8:0:0:0:0:0:1]",
        "test@[::fffF:127.0.0.1]",
        "example@valid-----hyphens.com",
        "example@valid-with-hyphens.com",
        %{"test@test"@example.com},
        "example@atm.#{"a" * 63}",
        "example@#{"a" * 63}.atm",
        "example@#{"a" * 63}.#{"b" * 10}.atm",
        # Localhost:
        "test@localhost",
        # Punycode:
        "test@domain.with.idn.tld.उदाहरण.परीक्षा",
        # Quoted strings:
        %{"\\\011"@example.com},
        # Max domain length, 63 characters (RFC 1034):
        "a@#{"a" * 63}.us",
      }.each do |email_address|
        Marten::Emailing::Address.valid?(email_address).should be_true, "#{email_address} should be valid"
      end
    end

    it "returns false for invalid email addresses" do
      {
        "",
        "abc",
        "abc@",
        "abc@bar",
        "a @x.cz",
        "abc@.com",
        "something@@somewexample.com",
        "test@127.0.0.1",
        "test@[127.0.0.256]",
        "test@[2001:db8::12345]",
        "test@[2001:db8:0:0:0:0:1]",
        "test@[::ffff:127.0.0.256]",
        "test@[2001:dg8::1]",
        "test@[2001:dG8:0:0:0:0:0:1]",
        "test@[::fTzF:127.0.0.1]",
        "example@invalid-.com",
        "example@-invalid.com",
        "example@invalid.com-",
        "example@inv-.alid-.com",
        "example@inv-.-alid.com",
        %{test@example.com\n\n<script src="x.js">},
        "example@atm.#{"a" * 64}",
        "example@#{"b" * 64}.atm.#{"a" * 63}",
        # Quoted strings:
        %{"\\\012"@example.com},
        # No trailing dots:
        "trailingdot@shouldfail.com.",
        # Max domain length, 63 characters (RFC 1034):
        "a@#{"a" * 64}.us",
        # No trailing newlines in username or domain part:
        "a@b.com\n",
        "a\n@b.com",
        %{"test@test"\n@example.com},
      }.each do |email_address|
        Marten::Emailing::Address.valid?(email_address).should be_false, "#{email_address} should not be valid"
      end
    end
  end

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
