require "./spec_helper"

describe Marten::HTTP::Session::Store do
  describe "::get" do
    it "returns the store class corresponding to the passed store name string" do
      Marten::HTTP::Session::Store.get("cookie").should eq Marten::HTTP::Session::Store::Cookie
    end

    it "returns the store class corresponding to the passed store name symbol" do
      Marten::HTTP::Session::Store.get(:cookie).should eq Marten::HTTP::Session::Store::Cookie
    end

    it "raises the expected error if no store class is registered for the passed name" do
      expect_raises(
        Marten::HTTP::Session::Errors::UnknownStore,
        "Unknown session store 'unknown_store'"
      ) do
        Marten::HTTP::Session::Store.get("unknown_store")
      end
    end
  end

  describe "::register" do
    after_each do
      Marten::HTTP::Session::Store.registry.delete("__spec_test__")
    end

    it "allows to register a stores class from a name string" do
      Marten::HTTP::Session::Store.register("__spec_test__", Marten::HTTP::Session::StoreSpec::Test)
      Marten::HTTP::Session::Store.get("__spec_test__").should eq Marten::HTTP::Session::StoreSpec::Test
    end

    it "allows to register a tag class from a name symbol" do
      Marten::HTTP::Session::Store.register(:__spec_test__, Marten::HTTP::Session::StoreSpec::Test)
      Marten::HTTP::Session::Store.get(:__spec_test__).should eq Marten::HTTP::Session::StoreSpec::Test
    end
  end

  describe "::registry" do
    it "returns the expected stores" do
      Marten::HTTP::Session::Store.registry.size.should eq 1
      Marten::HTTP::Session::Store.registry["cookie"].should eq Marten::HTTP::Session::Store::Cookie
    end
  end
end

module Marten::HTTP::Session::StoreSpec
  class Test < Marten::HTTP::Session::Store::Base
    def create : Nil
    end

    def flush : Nil
    end

    def load : SessionHash
      SessionHash.new
    end

    def save : Nil
    end
  end
end
