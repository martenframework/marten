require "./spec_helper"

describe Marten::Cache::Store::Null do
  describe "#clear" do
    it "completes as expected" do
      store = Marten::Cache::Store::Null.new

      store.clear.should be_nil
    end
  end

  describe "#decrement" do
    it "always returns 0" do
      store = Marten::Cache::Store::Null.new
      store.write("foo", "bar")

      store.decrement("foo").should eq 0
      store.decrement("unknown", amount: 2).should eq 0
    end
  end

  describe "#delete" do
    it "always returns false" do
      store = Marten::Cache::Store::Null.new
      store.write("foo", "bar")

      store.delete("foo").should be_false
      store.delete("unknown").should be_false
    end
  end

  describe "#increment" do
    it "always returns 0" do
      store = Marten::Cache::Store::Null.new
      store.write("foo", "bar")

      store.increment("foo").should eq 0
      store.increment("unknown", amount: 2).should eq 0
    end
  end

  describe "#read" do
    it "always returns nil" do
      store = Marten::Cache::Store::Null.new
      store.write("foo", "bar")

      store.read("foo").should be_nil
      store.read("unknown").should be_nil
    end
  end

  describe "#write" do
    it "does nothing" do
      store = Marten::Cache::Store::Null.new

      store.write("foo", "bar")

      store.read("foo").should be_nil
      store.read("unknown").should be_nil
    end
  end
end
