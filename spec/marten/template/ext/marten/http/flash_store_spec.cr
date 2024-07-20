require "./spec_helper"

describe Marten::HTTP::FlashStore do
  describe "#resolve_template_attribute" do
    it "can return whether the store is empty" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: [] of String)

      flash_store.resolve_template_attribute("empty?").should be_false

      flash_store.clear
      flash_store.resolve_template_attribute("empty?").should be_true
    end

    it "can return the size of the store" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: [] of String)

      flash_store.resolve_template_attribute("size").should eq 2

      flash_store.clear
      flash_store.resolve_template_attribute("size").should eq 0
    end

    it "can return a specific flash message" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: [] of String)

      flash_store.resolve_template_attribute("foo").should eq "bar"
      flash_store.resolve_template_attribute("alert").should eq "bad"
    end

    it "returns nil if the flash message is not found" do
      flash_store = Marten::HTTP::FlashStore.new(flashes: {"foo" => "bar", "alert" => "bad"}, discard: [] of String)

      flash_store.resolve_template_attribute("unknown").should be_nil
    end
  end
end
