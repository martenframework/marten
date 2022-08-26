require "./spec_helper"

describe Marten::HTTP::Session::Store::Base do
  describe "#[]" do
    it "returns the value corresponding to the passed key string" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store["foo"].should eq "bar"
    end

    it "returns the value corresponding to the passed key symbol" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store[:foo].should eq "bar"
    end

    it "raises if the passed key is not found" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      expect_raises(KeyError) { store["unknown"] }
    end

    it "sets the store as accessed" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store[:foo].should eq "bar"
      store.accessed?.should be_true
    end
  end

  describe "#[]?" do
    it "returns the value corresponding to the passed key string" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store["foo"]?.should eq "bar"
    end

    it "returns the value corresponding to the passed key symbol" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store[:foo]?.should eq "bar"
    end

    it "returns nil if the passed key is not found" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store["unknown"]?.should be_nil
    end

    it "sets the store as accessed" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store[:foo]?.should eq "bar"
      store.accessed?.should be_true
    end
  end

  describe "#[]=" do
    it "allows to set a value from a key string" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store["testkey"] = "hello"
      store["testkey"].should eq "hello"
    end

    it "allows to set a value from a key symbol" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store[:testkey] = "hello"
      store["testkey"].should eq "hello"
    end

    it "marks the store as modified" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store["testkey"] = "hello"
      store.modified?.should be_true
    end
  end

  describe "#accessed?" do
    it "returns true if the store was accessed" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store[:foo]?.should eq "bar"
      store.accessed?.should be_true
    end

    it "returns false if the store was not accessed" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.accessed?.should be_false
    end
  end

  describe "#cycle_key" do
    it "cycles the key of a store whose data was already accessed" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store[:foo]?.should eq "bar"
      store.accessed?.should be_true

      store.cycle_key

      store[:foo]?.should eq "bar"
      store.session_key.should_not eq "sessionkey"
    end

    it "cycles the key of a store whose data was not already accessed" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.accessed?.should be_false

      store.cycle_key

      store[:foo]?.should eq "bar"
      store.session_key.should_not eq "sessionkey"
    end
  end

  describe "#delete" do
    it "deletes a key value associated with a given key string" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.delete("foo").should eq "bar"
    end

    it "deletes a key value associated with a given key symbol" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.delete(:foo).should eq "bar"
    end

    it "marks the store as modified" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.delete("foo").should eq "bar"
      store.modified?.should be_true
    end
  end

  describe "#each" do
    it "allows to iterate over the keys and values" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.each do |key, value|
        key.should eq "foo"
        value.should eq "bar"
      end
    end
  end

  describe "#empty?" do
    it "returns true if the store is empty" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.flush
      store.empty?.should be_true
    end

    it "returns false if the store is not empty" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store["test"] = "test"
      store.empty?.should be_false
    end

    it "returns false if the store is empty but a session key is set" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.empty?.should be_false
    end
  end

  describe "#fetch" do
    it "allows to retrieve a specific value using its key" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.fetch("foo") { "fallback" }.should eq "bar"
    end

    it "allows to retrieve a specific value using its key expressed as a symbol" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.fetch(:foo) { "fallback" }.should eq "bar"
    end

    it "allows to retrieve a specific value using its key and a default" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.fetch("foo", "fallback").should eq "bar"
    end

    it "allows to retrieve a specific value using its key expressed as a symbol and a default" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.fetch(:foo, "fallback").should eq "bar"
    end

    it "yields the key when not found" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.fetch("unknown") { |n| n }.should eq "unknown"
    end

    it "returns the default value if the key is not found" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.fetch("unknown", "fallback").should eq "fallback"
    end
  end

  describe "#has_key?" do
    it "returns true if a value is present for a key string" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.has_key?("foo").should be_true
    end

    it "returns true if a value is present for a key symbol" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.has_key?("foo").should be_true
    end

    it "returns false if a value is not present for a key string" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.has_key?("unknown").should be_false
    end

    it "returns false if a value is not present for a key symbol" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.has_key?("unknown").should be_false
    end
  end

  describe "#modified?" do
    it "returns true if the store was modified" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store["test"] = "test"
      store.modified?.should be_true
    end

    it "returns true if the store was not modified" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.modified?.should be_false
    end
  end

  describe "#session_key" do
    it "returns the session key" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.session_key.should eq "sessionkey"
    end
  end

  describe "#size" do
    it "returns the size of the sessions hash" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")
      store.size.should eq 1

      store["new"] = "other"
      store.size.should eq 2

      store.flush
      store.size.should eq 0
    end
  end
end

module Marten::HTTP::Session::Store::BaseSpec
  class Test < Marten::HTTP::Session::Store::Base
    def create : Nil
    end

    def flush : Nil
      @session_hash = SessionHash.new
      @session_key = nil
      @modified = true
    end

    def load : SessionHash
      {"foo" => "bar"}
    end

    def save : Nil
    end
  end
end
