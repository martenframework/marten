require "./spec_helper"

describe Marten::HTTP::Session::Store::Cookie do
  describe "#create" do
    it "does nothing and marks the store as modifed" do
      store = Marten::HTTP::Session::Store::Cookie.new(nil)
      store.create
      store.modified?.should be_true
    end
  end

  describe "#flush" do
    it "resets the session hash" do
      store = Marten::HTTP::Session::Store::Cookie.new(nil)
      store["foo"] = "bar"

      store.flush
      store.should be_empty
    end

    it "resets the session key" do
      store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")

      store.flush
      store.session_key.should be_nil
    end

    it "marks the store as modified" do
      store = Marten::HTTP::Session::Store::Cookie.new(nil)

      store.flush
      store.modified?.should be_true
    end
  end

  describe "#load" do
    it "decrypts and unsigns the session key to generate the session data hash" do
      encryptor = Marten::Core::Encryptor.new
      session_key = encryptor.encrypt({"foo" => "bar"}.to_json)

      store = Marten::HTTP::Session::Store::Cookie.new(session_key)

      store.load.should eq({"foo" => "bar"})
    end

    it "returns an empty session data hash if the session key is nil" do
      store = Marten::HTTP::Session::Store::Cookie.new(nil)
      store.load.should be_empty
    end

    it "returns an empty session data hash if the session key cannot be decrypted" do
      store = Marten::HTTP::Session::Store::Cookie.new("bad")
      store.load.should be_empty
    end
  end

  describe "#save" do
    it "sets the session key as the encrypted session data hash" do
      encryptor = Marten::Core::Encryptor.new

      store = Marten::HTTP::Session::Store::Cookie.new(nil)
      store["foo"] = "bar"
      store.save

      encryptor.decrypt!(store.session_key.not_nil!).should eq({"foo" => "bar"}.to_json)
    end

    it "marks the store as modified" do
      store = Marten::HTTP::Session::Store::Cookie.new(nil)
      store.save

      store.modified?.should be_true
    end
  end
end
