require "./spec_helper"

describe Marten do
  describe "#assets" do
    it "returns the assets engine" do
      Marten.assets.should be_a Marten::Asset::Engine
    end
  end

  describe "#cache" do
    it "returns the configured cache store" do
      Marten.cache.should eq Marten.settings.cache_store
    end
  end
end
