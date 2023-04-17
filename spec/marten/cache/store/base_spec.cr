require "./spec_helper"

describe Marten::Cache::Store::Base do
  describe "#delete" do
    it "deletes the entry associated with the passed key and returns true" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar")

      store.delete("foo").should be_true
      store.exists?("foo").should be_false
    end

    it "returns false if the passed key is not in the cache" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new

      store.delete("foo").should be_false
    end
  end

  describe "#exists?" do
    it "returns true if the passed key is in the cache" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar")

      store.exists?("foo").should be_true
    end

    it "returns true if the passed key associated with a version is in the cache" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", version: 2)

      store.exists?("foo", version: 2).should be_true
    end

    it "returns false if the passed key is not in the cache" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new

      store.exists?("foo").should be_false
    end

    it "returns false if the version of the passed key does not match the version of the key in the cache" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", version: 1)

      store.exists?("foo", version: 2).should be_false
    end
  end

  describe "#fetch" do
    it "returns the cached value if there is one" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar")

      store.fetch("foo") { "baz" }.should eq "bar"
    end

    it "returns the block value and write it to the cache if the key does not exist" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new

      store.fetch("foo") { "baz" }.should eq "baz"
      store.read("foo").should eq "baz"
    end

    it "returns the cached value if there is one that is not expired yet" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", expires_in: 10.minutes)

      store.fetch("foo", expires_in: 10.minutes) { "baz" }.should eq "bar"
    end

    it "returns the block value and write it to the cache if the key exists but is expired" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", expires_in: 2.hours)

      Timecop.freeze(Time.local + 4.hours) do
        store.fetch("foo", expires_in: 2.hours) { "baz" }.should eq "baz"
        store.read("foo").should eq "baz"
      end
    end

    it "returns the block value and write it to the cache if the key exists but is associated with another version" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", version: 1)

      store.fetch("foo", version: 2) { "baz" }.should eq "baz"
      store.read("foo").should eq "baz"
    end

    it "makes use of the store namespace when writting new entries to the cache" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(namespace: "test")

      store.fetch("foo") { "baz" }.should eq "baz"
      store.data.has_key?("test:foo").should be_true
    end

    it "returns the block value and write it to the cache if the key exists but the force option is used" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar")

      store.fetch("foo", force: true) { "baz" }.should eq "baz"
      store.read("foo").should eq "baz"
    end

    it "properly uses the store default expires_in value when writing new entries" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(expires_in: 120.seconds)

      store.fetch("foo") { "baz" }.should eq "baz"
      store.read("foo").should eq "baz"

      Timecop.freeze(Time.local + 121.seconds) do
        store.read("foo").should be_nil
      end
    end

    it "properly uses the custom expires_at value when writing new entries" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(expires_in: 120.seconds)

      store.fetch("foo", expires_at: Time.local + 60.seconds) { "baz" }.should eq "baz"
      store.read("foo").should eq "baz"

      Timecop.freeze(Time.local + 61.seconds) do
        store.read("foo").should be_nil
      end
    end

    it "properly uses the custom expires_in value when writing new entries" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(expires_in: 120.seconds)

      store.fetch("foo", expires_in: 60.seconds) { "baz" }.should eq "baz"
      store.read("foo").should eq "baz"

      Timecop.freeze(Time.local + 61.seconds) do
        store.read("foo").should be_nil
      end
    end

    it "properly makes use of the race condition TTL if one is specified" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(expires_in: 120.seconds)

      store.fetch("foo", expires_in: 60.seconds) { "original_value" }.should eq "original_value"
      store.read("foo").should eq "original_value"

      Timecop.freeze(Time.local + 61.seconds) do
        race_condition_val = nil
        channel = Channel(String).new

        spawn do
          val = store.fetch("foo", race_condition_ttl: 10.seconds) do
            sleep 0.5
            "new_value_1"
          end

          channel.send(val)
        end

        spawn do
          race_condition_val = store.fetch("foo", race_condition_ttl: 10.seconds) do
            "new_value_2"
          end
        end

        Fiber.yield

        channel.receive.should eq "new_value_1"
        race_condition_val.should eq "original_value"

        store.fetch("foo", race_condition_ttl: 1.second) { "dummy" }.should eq "new_value_1"
      end
    end

    it "uses the store compression policy by default" do
      store_with_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true)
      store_with_compress.fetch("foo") { "baz" * 1000 }.should eq "baz" * 1000
      store_with_compress.compress_counter.should eq 1

      store_without_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: false)
      store_without_compress.fetch("foo") { "baz" }.should eq "baz"
      store_without_compress.compress_counter.should eq 0
    end

    it "uses the store compression threshold by default" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true, compress_threshold: 100)

      store.fetch("foo1") { "baz" }.should eq "baz"
      store.compress_counter.should eq 0

      store.fetch("foo2") { "baz" * 100 }.should eq "baz" * 100
      store.compress_counter.should eq 1
    end

    it "uses the local compression threshold if specified" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true, compress_threshold: 50000)

      store.fetch("foo", compress: true, compress_threshold: 500) { "baz" * 100 }.should eq "baz" * 100
      store.compress_counter.should eq 1
    end

    it "does not compress if compression is locally disabled" do
      store_with_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true)
      store_with_compress.fetch("foo", compress: false) { "baz" * 1000 }.should eq "baz" * 1000
      store_with_compress.compress_counter.should eq 0

      store_without_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: false)
      store_without_compress.fetch("foo", compress: false) { "baz" * 1000 }.should eq "baz" * 1000
      store_without_compress.compress_counter.should eq 0
    end

    it "compresses if compression is locally enabled" do
      store_with_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true)
      store_with_compress.fetch("foo", compress: true) { "baz" * 1000 }.should eq "baz" * 1000
      store_with_compress.compress_counter.should eq 1

      store_without_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: false)
      store_without_compress.fetch("foo", compress: true) { "baz" * 1000 }.should eq "baz" * 1000
      store_without_compress.compress_counter.should eq 1
    end
  end

  describe "#read" do
    it "returns the cached value if there is one" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar")

      store.read("foo").should eq "bar"
    end

    it "returns the raw cached value if there is one" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", raw: true)
      store.write("xyz", "test")

      store.read("foo", raw: true).should eq "bar"
      store.read("xyz", raw: true).should_not eq "test"
    end

    it "returns nil if the key does not exist" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new

      store.read("foo").should be_nil
    end

    it "returns the cached value if there is one that is not expired yet" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", expires_in: 10.minutes)

      store.read("foo").should eq "bar"
    end

    it "returns nil and delete the entry if the key exists but is expired" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", expires_in: 2.hours)

      Timecop.freeze(Time.local + 4.hours) do
        store.read("foo").should be_nil
      end

      store.data.should be_empty
    end

    it "returns the cached value if there is one that matches the passed version" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", version: 2)

      store.read("foo", version: 2).should eq "bar"
    end

    it "returns nil if the key exists but is associated with another version" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", version: 1)

      store.read("foo", version: 2).should be_nil
    end

    it "makes use of the store namespace when reading new entries from the cache" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(namespace: "test")
      store.write("foo", "baz")

      store.read("foo").should eq "baz"
    end
  end

  describe "#write" do
    it "writes a store value as expected" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new

      store.write("foo", "bar")
      store.read("foo").should eq "bar"
    end

    it "writes a raw valie to the store" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new
      store.write("foo", "bar", raw: true)

      store.read("foo", raw: true).should eq "bar"
    end

    it "properly uses the store default expires_in value" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(expires_in: 120.seconds)

      store.write("foo", "bar")
      store.read("foo").should eq "bar"

      Timecop.freeze(Time.local + 121.seconds) do
        store.read("foo").should be_nil
      end
    end

    it "properly uses the custom expires_at value" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(expires_in: 120.seconds)

      store.write("foo", "bar", expires_at: Time.local + 60.seconds)
      store.read("foo").should eq "bar"

      Timecop.freeze(Time.local + 61.seconds) do
        store.read("foo").should be_nil
      end
    end

    it "properly uses the custom expires_in value" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(expires_in: 120.seconds)

      store.write("foo", "bar", expires_in: 60.seconds)
      store.read("foo").should eq "bar"

      Timecop.freeze(Time.local + 61.seconds) do
        store.read("foo").should be_nil
      end
    end

    it "uses the store compression policy by default" do
      store_with_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true)
      store_with_compress.write("foo", "baz" * 1000)
      store_with_compress.read("foo").should eq "baz" * 1000
      store_with_compress.compress_counter.should eq 1

      store_without_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: false)
      store_without_compress.write("foo", "baz")
      store_without_compress.read("foo").should eq "baz"
      store_without_compress.compress_counter.should eq 0
    end

    it "uses the store compression threshold by default" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true, compress_threshold: 100)

      store.write("foo1", "baz")
      store.read("foo1").should eq "baz"
      store.compress_counter.should eq 0

      store.write("foo2", "baz" * 100)
      store.read("foo2").should eq "baz" * 100
      store.compress_counter.should eq 1
    end

    it "uses the local compression threshold if specified" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true, compress_threshold: 50000)

      store.write("foo", "baz" * 100, compress: true, compress_threshold: 500)
      store.read("foo").should eq "baz" * 100
      store.compress_counter.should eq 1
    end

    it "does not compress if compression is locally disabled" do
      store_with_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true)
      store_with_compress.write("foo", "baz" * 1000, compress: false)
      store_with_compress.read("foo").should eq "baz" * 1000
      store_with_compress.compress_counter.should eq 0

      store_without_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: false)
      store_without_compress.write("foo", "baz" * 1000, compress: false)
      store_without_compress.read("foo").should eq "baz" * 1000
      store_without_compress.compress_counter.should eq 0
    end

    it "compresses if compression is locally enabled" do
      store_with_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: true)
      store_with_compress.write("foo", "baz" * 1000, compress: true)
      store_with_compress.read("foo").should eq "baz" * 1000
      store_with_compress.compress_counter.should eq 1

      store_without_compress = Marten::Cache::Store::BaseSpec::TestStore.new(compress: false)
      store_without_compress.write("foo", "baz" * 1000, compress: true)
      store_without_compress.read("foo").should eq "baz" * 1000
      store_without_compress.compress_counter.should eq 1
    end

    it "uses the store version as expected" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(version: 1)
      store.write("foo", "bar")

      store.read("foo", version: 1).should eq "bar"
      store.read("foo", version: 2).should be_nil
    end

    it "uses the local version as expected" do
      store = Marten::Cache::Store::BaseSpec::TestStore.new(version: 1)
      store.write("foo", "bar", version: 2)

      store.read("foo", version: 1).should be_nil
      store.read("foo", version: 2).should eq "bar"
    end
  end
end

module Marten::Cache::Store::BaseSpec
  class TestStore < Marten::Cache::Store::Memory
    property compress_counter = 0

    getter data

    private def compress(data : String) : String
      self.compress_counter += 1

      super
    end
  end
end
