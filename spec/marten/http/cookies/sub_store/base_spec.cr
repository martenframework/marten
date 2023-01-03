require "./spec_helper"

describe Marten::HTTP::Cookies::SubStore::Base do
  describe "#[]" do
    it "returns the fetched value from a key string if it exists" do
      cookies = Marten::HTTP::Cookies.new
      cookies.set("foo", "bar")
      store = Marten::HTTP::Cookies::SubStore::BaseSpec::TestStore.new(cookies)
      store["foo"].should eq "bar"
    end

    it "returns the fetched value from a key symbol if it exists" do
      cookies = Marten::HTTP::Cookies.new
      cookies.set("foo", "bar")
      store = Marten::HTTP::Cookies::SubStore::BaseSpec::TestStore.new(cookies)
      store[:foo].should eq "bar"
    end

    it "raises KeyError if the specified key does not exist" do
      cookies = Marten::HTTP::Cookies.new
      store = Marten::HTTP::Cookies::SubStore::BaseSpec::TestStore.new(cookies)
      expect_raises(KeyError) { store[:unknown] }
    end
  end

  describe "#[]?" do
    it "returns the fetched value from a key string if it exists" do
      cookies = Marten::HTTP::Cookies.new
      cookies.set("foo", "bar")
      store = Marten::HTTP::Cookies::SubStore::BaseSpec::TestStore.new(cookies)
      store["foo"]?.should eq "bar"
    end

    it "returns the fetched value from a key symbol if it exists" do
      cookies = Marten::HTTP::Cookies.new
      cookies.set("foo", "bar")
      store = Marten::HTTP::Cookies::SubStore::BaseSpec::TestStore.new(cookies)
      store[:foo]?.should eq "bar"
    end

    it "returns nil if the specified key does not exist" do
      cookies = Marten::HTTP::Cookies.new
      store = Marten::HTTP::Cookies::SubStore::BaseSpec::TestStore.new(cookies)
      store[:unknown]?.should be_nil
    end
  end

  describe "#[]=" do
    it "sets the passed cookie value with a key string" do
      cookies = Marten::HTTP::Cookies.new
      store = Marten::HTTP::Cookies::SubStore::BaseSpec::TestStore.new(cookies)
      store["foo"] = "bar"
      store["foo"].should eq "bar"
    end

    it "sets the passed cookie value with a key symbol" do
      cookies = Marten::HTTP::Cookies.new
      store = Marten::HTTP::Cookies::SubStore::BaseSpec::TestStore.new(cookies)
      store[:foo] = "bar"
      store[:foo].should eq "bar"
    end
  end
end

module Marten::HTTP::Cookies::SubStore::BaseSpec
  class TestStore < Marten::HTTP::Cookies::SubStore::Base
    def fetch(name : String | Symbol, &)
      store[name]
    rescue KeyError
      yield name
    end

    def fetch(name : String | Symbol, default = nil)
      fetch(name) { default }
    end

    def set(name : String | Symbol, value, **kwargs) : Nil
      store.set(name, value.to_s, **kwargs)
    end
  end
end
