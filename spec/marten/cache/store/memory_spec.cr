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

  describe "#decrement" do
    it "can decrement an existing integer value" do
      store = Marten::Cache::Store::Memory.new
      2.times { store.increment("foo") }

      store.decrement("foo").should eq 1
      store.read("foo").try(&.to_i).should eq 1
    end

    it "can decrement an existing integer value when a namespace is used" do
      store = Marten::Cache::Store::Memory.new(namespace: "ns")
      2.times { store.increment("foo") }

      store.decrement("foo").should eq 1
      store.read("foo").try(&.to_i).should eq 1
    end

    it "can decrement an existing integer value for a key that is not expired" do
      store = Marten::Cache::Store::Memory.new
      2.times { store.increment("foo", expires_in: 2.hours) }

      store.decrement("foo").should eq 1
      store.read("foo").try(&.to_i).should eq 1
    end

    it "can decrement an existing integer value if the specified version matches the persisted one" do
      store = Marten::Cache::Store::Memory.new
      2.times { store.increment("foo", version: 2) }

      store.decrement("foo", version: 2).should eq 1
      store.read("foo", version: 2).try(&.to_i).should eq 1
    end

    it "can decrement an existing integer value by a specific amount" do
      store = Marten::Cache::Store::Memory.new
      5.times { store.increment("foo") }

      store.decrement("foo", amount: 3).should eq 2
      store.read("foo").try(&.to_i).should eq 2
    end

    it "writes the amount value to the cache in case the key does not exist" do
      store = Marten::Cache::Store::Memory.new

      store.decrement("foo").should eq -1
      store.read("foo").try(&.to_i).should eq -1

      store.decrement("bar", amount: 2).should eq -2
      store.read("bar").try(&.to_i).should eq -2
    end

    it "writes the amount value to the cache in case the key is expired" do
      store = Marten::Cache::Store::Memory.new
      5.times { store.increment("foo", expires_in: 2.hours) }
      5.times { store.increment("bar", expires_in: 2.hours) }

      Timecop.freeze(Time.local + 4.hours) do
        store.decrement("foo").should eq -1
        store.read("foo").try(&.to_i).should eq -1

        store.decrement("bar", amount: 2).should eq -2
        store.read("bar").try(&.to_i).should eq -2
      end
    end

    it "writes the amount value to the cache in case the key version does not match the persisted version" do
      store = Marten::Cache::Store::Memory.new
      5.times { store.increment("foo", version: 1) }
      5.times { store.increment("bar", version: 1) }

      store.decrement("foo", version: 2).should eq -1
      store.read("foo", version: 2).try(&.to_i).should eq -1

      store.decrement("bar", amount: 2, version: 2).should eq -2
      store.read("bar", version: 2).try(&.to_i).should eq -2
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

  describe "#increment" do
    it "can increment an existing integer value" do
      store = Marten::Cache::Store::Memory.new
      2.times { store.increment("foo") }

      store.increment("foo").should eq 3
      store.read("foo").try(&.to_i).should eq 3
    end

    it "can increment an existing integer value when a namespace is used" do
      store = Marten::Cache::Store::Memory.new(namespace: "ns")
      2.times { store.increment("foo") }

      store.increment("foo").should eq 3
      store.read("foo").try(&.to_i).should eq 3
    end

    it "can increment an existing integer value for a key that is not expired" do
      store = Marten::Cache::Store::Memory.new
      2.times { store.increment("foo", expires_in: 2.hours) }

      store.increment("foo").should eq 3
      store.read("foo").try(&.to_i).should eq 3
    end

    it "can increment an existing integer value if the specified version matches the persisted one" do
      store = Marten::Cache::Store::Memory.new
      2.times { store.increment("foo", version: 2) }

      store.increment("foo", version: 2).should eq 3
      store.read("foo", version: 2).try(&.to_i).should eq 3
    end

    it "can increment an existing integer value by a specific amount" do
      store = Marten::Cache::Store::Memory.new
      5.times { store.increment("foo") }

      store.increment("foo", amount: 3).should eq 8
      store.read("foo").try(&.to_i).should eq 8
    end

    it "writes the amount value to the cache in case the key does not exist" do
      store = Marten::Cache::Store::Memory.new

      store.increment("foo").should eq 1
      store.read("foo").try(&.to_i).should eq 1

      store.increment("bar", amount: 2).should eq 2
      store.read("bar").try(&.to_i).should eq 2
    end

    it "writes the amount value to the cache in case the key is expired" do
      store = Marten::Cache::Store::Memory.new
      5.times { store.increment("foo", expires_in: 2.hours) }
      5.times { store.increment("bar", expires_in: 2.hours) }

      Timecop.freeze(Time.local + 4.hours) do
        store.increment("foo").should eq 1
        store.read("foo").try(&.to_i).should eq 1

        store.increment("bar", amount: 2).should eq 2
        store.read("bar").try(&.to_i).should eq 2
      end
    end

    it "writes the amount value to the cache in case the key version does not match the persisted version" do
      store = Marten::Cache::Store::Memory.new
      5.times { store.increment("foo", version: 1) }
      5.times { store.increment("bar", version: 1) }

      store.increment("foo", version: 2).should eq 1
      store.read("foo", version: 2).try(&.to_i).should eq 1

      store.increment("bar", amount: 2, version: 2).should eq 2
      store.read("bar", version: 2).try(&.to_i).should eq 2
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
