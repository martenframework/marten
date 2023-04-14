require "./spec_helper"

describe Marten::Cache::Store::Memory do
  describe "#clear" do
    it "clears all the items in the cache" do
      store = Marten::Cache::Store::Memory.new
      store.write("foo", "bar")
      store.write("xyz", "test")

      store.clear

      store.read("foo").should be_nil
      store.read("xyz").should be_nil
    end
  end

  describe "#delete" do
    it "deletes the entry associated with the passed key and returns true" do
      store = Marten::Cache::Store::Memory.new
      store.write("foo", "bar")

      store.delete("foo").should be_true
      store.exists?("foo").should be_false
    end

    it "returns false if the passed key is not in the cache" do
      store = Marten::Cache::Store::Memory.new

      store.delete("foo").should be_false
    end
  end

  describe "#exists?" do
    it "returns true if the passed key is in the cache" do
      store = Marten::Cache::Store::Memory.new
      store.write("foo", "bar")

      store.exists?("foo").should be_true
    end

    it "returns false if the passed key is not in the cache" do
      store = Marten::Cache::Store::Memory.new

      store.exists?("foo").should be_false
    end
  end

  describe "#read" do
    it "returns the cached value if there is one" do
      store = Marten::Cache::Store::Memory.new
      store.write("foo", "bar")

      store.read("foo").should eq "bar"
    end

    it "returns nil if the key does not exist" do
      store = Marten::Cache::Store::Memory.new

      store.read("foo").should be_nil
    end
  end

  describe "#write" do
    it "write a store value as expected" do
      store = Marten::Cache::Store::Memory.new

      store.write("foo", "bar")
      store.read("foo").should eq "bar"
    end
  end
end
