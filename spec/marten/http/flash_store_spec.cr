require "./spec_helper"

describe Marten::HTTP::FlashStore do
  describe "::from_session" do
    it "returns an empty store if the session store does not contain any flash messages" do
      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store = Marten::HTTP::FlashStore.from_session(session_store)

      flash_store.empty?.should be_true
    end

    it "returns a store containing the expected messages when there are no discard keys" do
      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_flash"] = {
        "discard" => [] of String,
        "flashes" => {"foo" => "bar", "alert" => "bad"},
      }.to_json

      flash_store = Marten::HTTP::FlashStore.from_session(session_store)

      flash_store.empty?.should be_false
      flash_store["foo"].should eq "bar"
      flash_store["alert"].should eq "bad"
    end

    it "returns a store containing the expected messages when there are discard keys" do
      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_flash"] = {
        "discard" => ["foo", "xyz"] of String,
        "flashes" => {"foo" => "bar", "alert" => "bad", "xyz" => "test"},
      }.to_json

      flash_store = Marten::HTTP::FlashStore.from_session(session_store)

      flash_store.empty?.should be_false
      flash_store.size.should eq 1
      flash_store.has_key?("foo").should be_false
      flash_store.has_key?("xyz").should be_false
      flash_store["alert"].should eq "bad"
    end
  end

  describe "#[]" do
    it "returns the message associated with a key expressed as a string" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store["foo"].should eq "bar"
    end

    it "returns the message associated with a key expressed as a symbol" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store[:foo].should eq "bar"
    end

    it "raises a KeyError if the key is not found" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      expect_raises(KeyError) { flash_store["unknown"] }
    end
  end

  describe "#[]?" do
    it "returns the message associated with a key expressed as a string" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store["foo"]?.should eq "bar"
    end

    it "returns the message associated with a key expressed as a symbol" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store[:foo]?.should eq "bar"
    end

    it "returns nil if the key is not found" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store["unknown"]?.should be_nil
    end
  end

  describe "#[]=" do
    it "allows to set a new flash message using a key expressed as a string" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"alert" => "bad"})
      flash_store["foo"] = "bar"
      flash_store["foo"].should eq "bar"
    end

    it "allows to set a new flash message using a key expressed as a symbol" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"alert" => "bad"})
      flash_store[:foo] = "bar"
      flash_store[:foo].should eq "bar"
    end

    it "removes the inserted key from the discarded set of keys" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {} of String => String, discard: ["foo", "other"])
      flash_store[:foo] = "bar"
      flash_store[:foo].should eq "bar"

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq({"discard" => [] of String, "flashes" => {"foo" => "bar"}}.to_json)
    end
  end

  describe "#clear" do
    it "clears flash messages and discarded keys" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar"}, discard: ["foo", "other"])

      flash_store.clear
      flash_store.empty?.should be_true

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)
      session_store["_flash"]?.should be_nil
    end

    it "returns the store itself" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar"}, discard: ["foo", "other"])
      flash_store.clear.should be flash_store
    end
  end

  describe "#delete" do
    it "deletes flash messages and discarded messages using a key expressed as a string" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      flash_store.delete("foo")
      flash_store.delete("other")

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq({"discard" => [] of String, "flashes" => {"alert" => "bad"}}.to_json)
    end

    it "deletes flash messages and discarded messages using a key expressed as a symbol" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      flash_store.delete(:foo)
      flash_store.delete(:other)

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq({"discard" => [] of String, "flashes" => {"alert" => "bad"}}.to_json)
    end

    it "returns nil if the passed key is not found" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])
      flash_store.delete("unknown").should be_nil
    end

    it "calls the specified block if the passed key is not found" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      block_called = false
      flash_store.delete("unknown") { block_called = true }

      block_called.should be_true
    end
  end

  describe "#discard" do
    it "discards a specific key expressed as string" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      flash_store.discard("foo")

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq({"discard" => [] of String, "flashes" => {"alert" => "bad"}}.to_json)
    end

    it "discards a specific key expressed as symbol" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      flash_store.discard(:foo)

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq({"discard" => [] of String, "flashes" => {"alert" => "bad"}}.to_json)
    end

    it "discards all the flash messages" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      flash_store.discard

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"]?.should be_nil
    end

    it "returns the discarded key value when such key is specified" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])
      flash_store.discard("foo").should eq "bar"
    end

    it "returns the whole flash store object when no key is specified" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])
      flash_store.discard.should eq flash_store
    end
  end

  describe "#fetch" do
    it "returns the message associated with a key expressed as a string" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store.fetch("foo", "default").should eq "bar"
    end

    it "returns the message associated with a key expressed as a symbol" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store.fetch(:foo, "default").should eq "bar"
    end

    it "returns the specified default value if the key is not found" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store.fetch("unknown", "default").should eq "default"
    end

    it "yields the key if it is not found" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      yielded_value = nil
      flash_store.fetch("unknown") { |y| yielded_value = y }
      yielded_value.should eq "unknown"
    end
  end

  describe "#has_key?" do
    it "returns true if there is a message associated with a key expressed as a string" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store.has_key?("foo").should be_true
    end

    it "returns true if there is a message associated with a key expressed as a symbol" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store.has_key?(:foo).should be_true
    end

    it "returns false if the key is not found" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})
      flash_store.has_key?("unknown").should be_false
    end
  end

  describe "#keep" do
    it "keeps a specific key expressed as string" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      flash_store.keep("foo")

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq(
        {"discard" => [] of String, "flashes" => {"foo" => "bar", "alert" => "bad"}}.to_json
      )
    end

    it "keeps a specific key expressed as symbol" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      flash_store.keep(:foo)

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq(
        {"discard" => [] of String, "flashes" => {"foo" => "bar", "alert" => "bad"}}.to_json
      )
    end

    it "keeps all the flash messages" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      flash_store.keep

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq(
        {"discard" => [] of String, "flashes" => {"foo" => "bar", "alert" => "bad"}}.to_json
      )
    end

    it "returns the kept key value when such key is specified" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])
      flash_store.keep("foo").should eq "bar"
    end

    it "returns the whole flash store object when no key is specified" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])
      flash_store.keep.should eq flash_store
    end
  end

  describe "#persist" do
    it "persists the expected flash messages when there are no discarded keys" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"})

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq(
        {"discard" => [] of String, "flashes" => {"foo" => "bar", "alert" => "bad"}}.to_json
      )
    end

    it "persists the expected flash messages when there are discarded keys" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      flash_store.persist(session_store)

      session_store["_flash"].should eq(
        {"discard" => [] of String, "flashes" => {"alert" => "bad"}}.to_json
      )
    end

    it "deletes any previously defined flash messages from the session store if the flash store is empty" do
      flash_store = Marten::HTTP::FlashStore.new

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_flash"] = "oldvalue"

      flash_store.persist(session_store)

      session_store["_flash"]?.should be_nil
    end
  end

  describe "#each" do
    it "allows to iterate over the flash messages" do
      iterated = [] of Array(String)

      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])
      flash_store.each do |k, v|
        iterated << [k, v]
      end

      iterated.should eq [["foo", "bar"], ["alert", "bad"]]
    end
  end

  describe "#empty?" do
    it "returns true if the store is empty" do
      flash_store = Marten::HTTP::FlashStore.new
      flash_store.empty?.should be_true
    end

    it "returns true if the store does not have flash messages, but only discarded keys" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {} of String => String, discard: ["foo", "bar"])
      flash_store.empty?.should be_true
    end

    it "returns false if the store is not empty" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])
      flash_store.empty?.should be_false
    end
  end

  describe "#size" do
    it "returns 0 if the store is empty" do
      flash_store = Marten::HTTP::FlashStore.new
      flash_store.size.should eq 0
    end

    it "returns the number of effective flash messages" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: ["foo", "other"])
      flash_store.size.should eq 2
    end
  end
end
