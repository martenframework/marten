require "./spec_helper"

describe Marten::Cache::Entry do
  describe "::new" do
    it "allows to create a new entry without expiration and without version" do
      entry = Marten::Cache::Entry.new("value")

      entry.value.should eq "value"
      entry.expires_at.should be_nil
      entry.version.should be_nil
    end

    it "allows to create a new entry with an expiration" do
      Timecop.freeze(Time.local) do
        entry = Marten::Cache::Entry.new("value", expires_in: 10.hours)

        entry.value.should eq "value"
        entry.expires_at.should eq 10.hours.to_f + Time.utc.to_unix_f
        entry.version.should be_nil
      end
    end

    it "allows to create a new entry with a version" do
      entry = Marten::Cache::Entry.new("value", version: 2)

      entry.value.should eq "value"
      entry.expires_at.should be_nil
      entry.version.should eq 2
    end
  end

  describe "::unpack" do
    it "unpacks a MessagePack-serialized value and initializes the corresponding entry" do
      entry = Marten::Cache::Entry.unpack({"value", nil, nil}.to_msgpack.hexstring)
      entry.value.should eq "value"
      entry.expires_at.should be_nil
      entry.version.should be_nil

      Timecop.freeze(Time.local) do
        expiration = 10.hours.to_f + Time.utc.to_unix_f
        entry_with_expiration = Marten::Cache::Entry.unpack({"value", expiration, nil}.to_msgpack.hexstring)
        entry_with_expiration.value.should eq "value"
        entry_with_expiration.expires_at.should eq expiration
        entry_with_expiration.version.should be_nil
      end

      entry_with_version = Marten::Cache::Entry.unpack({"value", nil, 2}.to_msgpack.hexstring)
      entry_with_version.value.should eq "value"
      entry_with_version.expires_at.should be_nil
      entry_with_version.version.should eq 2
    end
  end

  describe "#expired?" do
    it "returns false if the entry has no associated expiration" do
      entry = Marten::Cache::Entry.new("value")

      entry.expired?.should be_false
    end

    it "returns false if the entry is not expired" do
      entry = Marten::Cache::Entry.new("value", expires_in: 10.seconds)

      entry.expired?.should be_false
    end

    it "returns true if the entry is expired" do
      entry = Marten::Cache::Entry.new("value", expires_in: 10.seconds)

      Timecop.freeze(Time.local + 11.seconds) do
        entry.expired?.should be_true
      end
    end
  end

  describe "#expires_at" do
    it "returns the associated expiration timestamp" do
      entry_1 = Marten::Cache::Entry.new("value")
      entry_1.expires_at.should be_nil

      Timecop.freeze(Time.local) do
        entry_2 = Marten::Cache::Entry.new("value", expires_in: 10.hours)
        entry_2.expires_at.should eq 10.hours.to_f + Time.utc.to_unix_f
      end
    end
  end

  describe "#expires_at=" do
    it "allows to set the expiration timestamp" do
      entry = Marten::Cache::Entry.new("value", expires_in: 10.hours)
      entry.expires_at = 120.seconds.to_f + Time.utc.to_unix_f

      Timecop.freeze(Time.local + 121.seconds) do
        entry.expired?.should be_true
      end
    end
  end

  describe "#mismatched?" do
    it "returns false if the specified version is nil and the entry has no version" do
      entry = Marten::Cache::Entry.new("value")

      entry.mismatched?(nil).should be_false
    end

    it "returns false if the specified version is not nil and the entry has no version" do
      entry = Marten::Cache::Entry.new("value")

      entry.mismatched?(2).should be_false
    end

    it "returns false if the specified version is nill and the entry has a version" do
      entry = Marten::Cache::Entry.new("value", version: 2)

      entry.mismatched?(nil).should be_false
    end

    it "returns false if the specified version matches the entry version" do
      entry = Marten::Cache::Entry.new("value", version: 2)

      entry.mismatched?(2).should be_false
    end

    it "returns true if the specified version does not match the entry version" do
      entry = Marten::Cache::Entry.new("value", version: 1)

      entry.mismatched?(2).should be_true
    end
  end

  describe "#pack" do
    it "returns the expected MessagePack-serialized value for an entry without expiration and without version" do
      entry = Marten::Cache::Entry.new("value")

      entry.pack.should eq({"value", nil, nil}.to_msgpack.hexstring)
    end

    it "returns the expected MessagePack-serialized value for an entry with an expiration" do
      Timecop.freeze(Time.local) do
        entry = Marten::Cache::Entry.new("value", expires_in: 10.minutes)

        entry.pack.should eq({"value", 10.minutes.to_f + Time.utc.to_unix_f, nil}.to_msgpack.hexstring)
      end
    end

    it "returns the expected MessagePack-serialized value for an entry with a version" do
      entry = Marten::Cache::Entry.new("value", version: 2)

      entry.pack.should eq({"value", nil, 2}.to_msgpack.hexstring)
    end
  end

  describe "#value" do
    it "returns the entry value" do
      entry = Marten::Cache::Entry.new("value")
      entry.value.should eq "value"
    end
  end

  describe "#version" do
    it "returns the entry version" do
      entry_1 = Marten::Cache::Entry.new("value")
      entry_1.version.should be_nil

      entry_2 = Marten::Cache::Entry.new("value", version: 2)
      entry_2.version.should eq 2
    end
  end
end
