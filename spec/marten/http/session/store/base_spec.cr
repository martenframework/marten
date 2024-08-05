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

  describe "#expires_at_browser_close?" do
    it "returns false by default" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_at_browser_close?.should be_false
    end

    it "returns false if the session does not expire at browser close" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_at_browser_close = false

      store.expires_at_browser_close?.should be_false
    end

    it "returns true if the session expires at browser close" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_at_browser_close = true

      store.expires_at_browser_close?.should be_true
    end
  end

  describe "#expires_at_browser_close=" do
    it "allows to set that the session expires at browser close" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_at_browser_close = true

      store.expires_at_browser_close?.should be_true
    end

    it "allows to set that the session does not expire at browser close" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_at_browser_close = false

      store.expires_at_browser_close?.should be_false
    end

    it "marks the store as modified" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_at_browser_close = true

      store.modified?.should be_true
    end
  end

  describe "#expires_at" do
    it "returns the current time plus the sessions cookie max age by default" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      current_time = Time.local

      Timecop.freeze(current_time) do
        store.expires_at.should eq current_time + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)
      end
    end

    it "returns the current time plus the explicitly set expiration time if applicable" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_in = Time::Span.new(hours: 10)

      current_time = Time.local

      Timecop.freeze(current_time) do
        store.expires_at.should eq current_time + Time::Span.new(hours: 10)
      end
    end

    it "returns the explicitly defined expiration date time if applicable" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      current_time = Time.local

      Timecop.freeze(current_time) do
        store.expires_at = current_time + Time::Span.new(hours: 10)

        store.expires_at.should eq current_time + Time::Span.new(hours: 10)
      end
    end

    it "returns nil if the session expires at browser close" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_at_browser_close = true

      store.expires_at.should be_nil
    end
  end

  describe "#expires_at=" do
    it "allows to set a specific expiration date time" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      current_time = Time.local

      Timecop.freeze(current_time) do
        store.expires_at = current_time + Time::Span.new(hours: 10)

        store.expires_at.should eq current_time + Time::Span.new(hours: 10)
      end
    end

    it "marks the store as modified" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      current_time = Time.local

      Timecop.freeze(current_time) do
        store.expires_at = current_time + Time::Span.new(hours: 10)

        store.expires_at.should eq current_time + Time::Span.new(hours: 10)
        store.modified?.should be_true
      end
    end
  end

  describe "#expires_in" do
    it "returns the sessions cookie max age by default" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_in.should eq Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)
    end

    it "returns the explicitly set expiration time" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_in = Time::Span.new(hours: 10)

      store.expires_in.should eq Time::Span.new(hours: 10)
    end
  end

  describe "#expires_in=" do
    it "allows to set a specific expiration time" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_in = Time::Span.new(hours: 10)

      store.expires_in.should eq Time::Span.new(hours: 10)
    end

    it "allows to set a specific expiration time in seconds" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_in = 3600

      store.expires_in.should eq Time::Span.new(seconds: 3600)
    end

    it "marks the store as modified when setting a specific expiration time" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_in = Time::Span.new(hours: 10)

      store.expires_in.should eq Time::Span.new(hours: 10)
      store.modified?.should be_true
    end

    it "marks the store as modified when setting a specific expiration time in seconds" do
      store = Marten::HTTP::Session::Store::BaseSpec::Test.new("sessionkey")

      store.expires_in = 3600

      store.expires_in.should eq Time::Span.new(seconds: 3600)
      store.modified?.should be_true
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

    def clear_expired_entries : Nil
    end

    def save : Nil
    end
  end
end
