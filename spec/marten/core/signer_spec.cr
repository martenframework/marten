require "./spec_helper"

describe Marten::Core::Signer do
  describe "::new" do
    it "ensure the signer makes use of the passed key and algorithm to sign and unsign values" do
      signer = Marten::Core::Signer.new(key: "insecure", algorithm: OpenSSL::Algorithm::SHA1)
      signed_value = signer.sign("hello world")

      signed_value.split("--").first.should eq Base64.strict_encode("hello world")
      Base64.decode_string(signed_value.split("--").first).should eq "hello world"

      signed_value.split("--").last.should eq(
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Algorithm::SHA1,
          "insecure",
          Base64.strict_encode("hello world")
        )
      )

      signer.unsign(signed_value).should eq "hello world"
    end
  end

  describe "#sign" do
    it "creates a valid signature for a simple string value" do
      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world")

      signed_value.split("--").first.should eq Base64.strict_encode("hello world")
      Base64.decode_string(signed_value.split("--").first).should eq "hello world"

      signed_value.split("--").last.should eq(
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Algorithm::SHA256,
          Marten.settings.secret_key,
          Base64.strict_encode("hello world")
        )
      )

      signer.unsign(signed_value).should eq "hello world"
    end

    it "creates a valid signature for an expirable value" do
      expiry = Time.local + Time::Span.new(hours: 20)

      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world", expires: expiry)

      expected_metada = {
        "_marten" => {
          "value"   => Base64.strict_encode("hello world"),
          "expires" => Time::Format::RFC_3339.format(expiry.to_utc, fraction_digits: 0),
        },
      }

      signed_value.split("--").first.should eq Base64.strict_encode(expected_metada.to_json)
      Base64.decode_string(signed_value.split("--").first).should eq expected_metada.to_json

      signed_value.split("--").last.should eq(
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Algorithm::SHA256,
          Marten.settings.secret_key,
          Base64.strict_encode(expected_metada.to_json)
        )
      )

      signer.unsign(signed_value).should eq "hello world"
    end
  end

  describe "#unsign" do
    it "is able to verify a signed value" do
      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world")
      signer.unsign(signed_value).should eq "hello world"
    end

    it "is able to verify a signed value with an expiry" do
      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world", expires: Time.local + Time::Span.new(hours: 20))
      signer.unsign(signed_value).should eq "hello world"
    end

    it "works as expected for a serialized JSON object" do
      signer = Marten::Core::Signer.new
      value = {"foo" => "bar"}
      signed_value = signer.sign(value.to_json)
      signer.unsign(signed_value).should eq value.to_json
    end

    it "works as expected for a serialized JSON object with an expiry" do
      signer = Marten::Core::Signer.new
      value = {"foo" => "bar"}
      signed_value = signer.sign(value.to_json, expires: Time.local + Time::Span.new(hours: 20))
      signer.unsign(signed_value).should eq value.to_json
    end

    it "works as expected for a serialized empty JSON object" do
      signer = Marten::Core::Signer.new
      value = Hash(String, String).new
      signed_value = signer.sign(value.to_json)
      signer.unsign(signed_value).should eq value.to_json
    end

    it "returns nil if the signed value is expired" do
      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world", expires: Time.local - Time::Span.new(hours: 20))
      signer.unsign(signed_value).should be_nil
    end

    it "returns nil for a blank string" do
      signer = Marten::Core::Signer.new
      signer.unsign("").should be_nil
    end

    it "returns nil for a string containing the separator only" do
      signer = Marten::Core::Signer.new
      signer.unsign("--").should be_nil
    end

    it "returns nil if the string only contains the encoded data" do
      signer = Marten::Core::Signer.new
      signer.unsign("#{Base64.strict_encode("test")}--").should be_nil
    end

    it "returns nil if the string only contains the signature" do
      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world")
      signer.unsign("--#{signed_value.split("--").last}").should be_nil
    end

    it "returns nil for a string with an invalid encoding" do
      signer = Marten::Core::Signer.new
      signer.unsign(String.new(Bytes[255, 97])).should be_nil
    end

    it "returns nil if the signature is not the right one" do
      signer = Marten::Core::Signer.new
      signer.unsign("data--sig").should be_nil
    end

    it "returns nil if the Base64 decoding fails for the data" do
      signer = Marten::Core::Signer.new
      value = "bad val--" + OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, Marten.settings.secret_key, "bad val")
      signer.unsign(value).should be_nil
    end
  end

  describe "#unsign!" do
    it "is able to verify a signed value" do
      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world")
      signer.unsign!(signed_value).should eq "hello world"
    end

    it "is able to verify a signed value with an expiry" do
      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world", expires: Time.local + Time::Span.new(hours: 20))
      signer.unsign!(signed_value).should eq "hello world"
    end

    it "works as expected for a serialized JSON object" do
      signer = Marten::Core::Signer.new
      value = {"foo" => "bar"}
      signed_value = signer.sign(value.to_json)
      signer.unsign!(signed_value).should eq value.to_json
    end

    it "works as expected for a serialized JSON object with an expiry" do
      signer = Marten::Core::Signer.new
      value = {"foo" => "bar"}
      signed_value = signer.sign(value.to_json, expires: Time.local + Time::Span.new(hours: 20))
      signer.unsign!(signed_value).should eq value.to_json
    end

    it "works as expected for a serialized empty JSON object" do
      signer = Marten::Core::Signer.new
      value = Hash(String, String).new
      signed_value = signer.sign(value.to_json)
      signer.unsign!(signed_value).should eq value.to_json
    end

    it "raises if the signed value is expired" do
      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world", expires: Time.local - Time::Span.new(hours: 20))
      expect_raises(Marten::Core::Signer::InvalidSignatureError) { signer.unsign!(signed_value) }
    end

    it "raises for a blank string" do
      signer = Marten::Core::Signer.new
      expect_raises(Marten::Core::Signer::InvalidSignatureError) { signer.unsign!("") }
    end

    it "raises for a string containing the separator only" do
      signer = Marten::Core::Signer.new
      expect_raises(Marten::Core::Signer::InvalidSignatureError) { signer.unsign!("--") }
    end

    it "raises if the string only contains the encoded data" do
      signer = Marten::Core::Signer.new
      expect_raises(Marten::Core::Signer::InvalidSignatureError) { signer.unsign!("#{Base64.strict_encode("test")}--") }
    end

    it "raises if the string only contains the signature" do
      signer = Marten::Core::Signer.new
      signed_value = signer.sign("hello world")
      expect_raises(Marten::Core::Signer::InvalidSignatureError) do
        signer.unsign!("--#{signed_value.split("--").last}")
      end
    end

    it "raises for a string with an invalid encoding" do
      signer = Marten::Core::Signer.new
      expect_raises(Marten::Core::Signer::InvalidSignatureError) { signer.unsign!(String.new(Bytes[255, 97])) }
    end

    it "raises if the signature is not the right one" do
      signer = Marten::Core::Signer.new
      expect_raises(Marten::Core::Signer::InvalidSignatureError) { signer.unsign!("data--sig") }
    end

    it "raises if the Base64 decoding fails for the data" do
      signer = Marten::Core::Signer.new
      value = "bad val--" + OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, Marten.settings.secret_key, "bad val")
      expect_raises(Marten::Core::Signer::InvalidSignatureError) { signer.unsign!(value) }
    end
  end
end
