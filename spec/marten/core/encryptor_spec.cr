require "./spec_helper"

describe Marten::Core::Encryptor do
  describe "::new" do
    it "ensure the encryptor makes use of the passed key and algorithm to encrypt and decrypt values" do
      key = "a" * 32

      encryptor = Marten::Core::Encryptor.new(key: key, cipher_algorithm: "aes-128-cbc")
      encrypted_value = encryptor.encrypt("hello world")

      cipher = OpenSSL::Cipher.new("aes-128-cbc")
      signer = Marten::Core::Signer.new(key: key)
      unsigned_value = signer.unsign!(encrypted_value)
      unsigned_value = unsigned_value.hexbytes

      data = unsigned_value[0, unsigned_value.size - 16]
      iv = unsigned_value[unsigned_value.size - 16, 16]

      cipher.decrypt
      cipher.key = key
      cipher.iv = iv

      decrypted_data = IO::Memory.new
      decrypted_data.write(cipher.update(data))
      decrypted_data.write(cipher.final)

      decrypted_data.rewind
      decrypted_data.gets_to_end.should eq "hello world"
    end
  end

  describe "#encrypt" do
    it "creates a valid signature and encrypted value for a simple string value" do
      signer = Marten::Core::Signer.new
      encryptor = Marten::Core::Encryptor.new

      encrypted_value = encryptor.encrypt("hello world")

      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      unsigned_value = signer.unsign!(encrypted_value)
      unsigned_value = unsigned_value.hexbytes

      data = unsigned_value[0, unsigned_value.size - 16]
      iv = unsigned_value[unsigned_value.size - 16, 16]

      cipher.decrypt
      cipher.key = Marten.settings.secret_key
      cipher.iv = iv

      decrypted_data = IO::Memory.new
      decrypted_data.write(cipher.update(data))
      decrypted_data.write(cipher.final)

      decrypted_data.rewind
      decrypted_data.gets_to_end.should eq "hello world"

      encryptor.decrypt(encrypted_value).should eq "hello world"
    end
  end

  describe "#decrypt" do
    it "is able to verify and decrypt an encrypted value" do
      encryptor = Marten::Core::Encryptor.new
      encrypted_value = encryptor.encrypt("hello world")
      encryptor.decrypt(encrypted_value).should eq "hello world"
    end

    it "is able to verify and decrypt an encrypted value with an expiry" do
      encryptor = Marten::Core::Encryptor.new
      encrypted_value = encryptor.encrypt("hello world", expires: Time.local + Time::Span.new(hours: 20))
      encryptor.decrypt(encrypted_value).should eq "hello world"
    end

    it "works as expected for a serialized JSON object" do
      encryptor = Marten::Core::Encryptor.new
      value = {"foo" => "bar"}
      encrypted_value = encryptor.encrypt(value.to_json)
      encryptor.decrypt(encrypted_value).should eq value.to_json
    end

    it "works as expected for a serialized JSON object with an expiry" do
      encryptor = Marten::Core::Encryptor.new
      value = {"foo" => "bar"}
      encrypted_value = encryptor.encrypt(value.to_json, expires: Time.local + Time::Span.new(hours: 20))
      encryptor.decrypt(encrypted_value).should eq value.to_json
    end

    it "works as expected for a serialized empty JSON object" do
      encryptor = Marten::Core::Encryptor.new
      value = Hash(String, String).new
      encrypted_value = encryptor.encrypt(value.to_json)
      encryptor.decrypt(encrypted_value).should eq value.to_json
    end

    it "returns nil if the signed value is expired" do
      encryptor = Marten::Core::Encryptor.new
      encrypted_value = encryptor.encrypt("hello world", expires: Time.local - Time::Span.new(hours: 20))
      encryptor.decrypt(encrypted_value).should be_nil
    end

    it "returns nil for a blank string" do
      encryptor = Marten::Core::Encryptor.new
      encryptor.decrypt("").should be_nil
    end

    it "returns nil for a string containing the separator only" do
      encryptor = Marten::Core::Encryptor.new
      encryptor.decrypt("--").should be_nil
    end

    it "returns nil if the string only contains the encoded data" do
      encryptor = Marten::Core::Encryptor.new
      encryptor.decrypt("#{Base64.strict_encode("test")}--").should be_nil
    end

    it "returns nil if the string only contains the signature" do
      encryptor = Marten::Core::Encryptor.new
      encrypted_value = encryptor.encrypt("hello world")
      encryptor.decrypt("--#{encrypted_value.split("--").last}").should be_nil
    end

    it "returns nil for a string with an invalid encoding" do
      encryptor = Marten::Core::Encryptor.new
      encryptor.decrypt(String.new(Bytes[255, 97])).should be_nil
    end

    it "returns nil if the signature is not the right one" do
      encryptor = Marten::Core::Encryptor.new
      encryptor.decrypt("data--sig").should be_nil
    end

    it "returns nil if the Base64 decoding fails for the data" do
      encryptor = Marten::Core::Encryptor.new
      value = "bad val--" + OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, Marten.settings.secret_key, "bad val")
      encryptor.decrypt(value).should be_nil
    end
  end

  describe "#decrypt!" do
    it "is able to verify an encrypted ans signed value" do
      encryptor = Marten::Core::Encryptor.new
      encrypted_value = encryptor.encrypt("hello world")
      encryptor.decrypt!(encrypted_value).should eq "hello world"
    end

    it "is able to verify an encrypted ans signed value with an expiry" do
      encryptor = Marten::Core::Encryptor.new
      encrypted_value = encryptor.encrypt("hello world", expires: Time.local + Time::Span.new(hours: 20))
      encryptor.decrypt!(encrypted_value).should eq "hello world"
    end

    it "works as expected for a serialized JSON object" do
      encryptor = Marten::Core::Encryptor.new
      value = {"foo" => "bar"}
      encrypted_value = encryptor.encrypt(value.to_json)
      encryptor.decrypt!(encrypted_value).should eq value.to_json
    end

    it "works as expected for a serialized JSON object with an expiry" do
      encryptor = Marten::Core::Encryptor.new
      value = {"foo" => "bar"}
      encrypted_value = encryptor.encrypt(value.to_json, expires: Time.local + Time::Span.new(hours: 20))
      encryptor.decrypt!(encrypted_value).should eq value.to_json
    end

    it "works as expected for a serialized empty JSON object" do
      encryptor = Marten::Core::Encryptor.new
      value = Hash(String, String).new
      encrypted_value = encryptor.encrypt(value.to_json)
      encryptor.decrypt!(encrypted_value).should eq value.to_json
    end

    it "raises if the encrypted and signed value is expired" do
      encryptor = Marten::Core::Encryptor.new
      encrypted_value = encryptor.encrypt("hello world", expires: Time.local - Time::Span.new(hours: 20))
      expect_raises(Marten::Core::Encryptor::InvalidValueError) { encryptor.decrypt!(encrypted_value) }
    end

    it "raises for a blank string" do
      encryptor = Marten::Core::Encryptor.new
      expect_raises(Marten::Core::Encryptor::InvalidValueError) { encryptor.decrypt!("") }
    end

    it "raises for a string containing the separator only" do
      encryptor = Marten::Core::Encryptor.new
      expect_raises(Marten::Core::Encryptor::InvalidValueError) { encryptor.decrypt!("--") }
    end

    it "raises if the string only contains the encoded data" do
      encryptor = Marten::Core::Encryptor.new
      expect_raises(Marten::Core::Encryptor::InvalidValueError) do
        encryptor.decrypt!("#{Base64.strict_encode("test")}--")
      end
    end

    it "raises if the string only contains the signature" do
      encryptor = Marten::Core::Encryptor.new
      encrypted_value = encryptor.encrypt("hello world")
      expect_raises(Marten::Core::Encryptor::InvalidValueError) do
        encryptor.decrypt!("--#{encrypted_value.split("--").last}")
      end
    end

    it "raises for a string with an invalid encoding" do
      encryptor = Marten::Core::Encryptor.new
      expect_raises(Marten::Core::Encryptor::InvalidValueError) { encryptor.decrypt!(String.new(Bytes[255, 97])) }
    end

    it "raises if the signature is not the right one" do
      encryptor = Marten::Core::Encryptor.new
      expect_raises(Marten::Core::Encryptor::InvalidValueError) { encryptor.decrypt!("data--sig") }
    end

    it "raises if the Base64 decoding fails for the data" do
      encryptor = Marten::Core::Encryptor.new
      value = "bad val--" + OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, Marten.settings.secret_key, "bad val")
      expect_raises(Marten::Core::Encryptor::InvalidValueError) { encryptor.decrypt!(value) }
    end
  end
end
