require "./spec_helper"

describe Marten::DB::Router::Base do
  describe "#db_for_read" do
    it "returns nil by default" do
      router = Marten::DB::Router::BaseSpec::TestRouter.new

      router.db_for_read(Tag).should be_nil
    end

    it "accepts optional hints" do
      router = Marten::DB::Router::BaseSpec::TestRouter.new
      tag = Tag.new(name: "coding", is_active: true)
      hints = Marten::DB::Router::Hints.new(instance: tag)

      router.db_for_read(Tag, hints).should be_nil
    end
  end

  describe "#db_for_write" do
    it "returns nil by default" do
      router = Marten::DB::Router::BaseSpec::TestRouter.new

      router.db_for_write(Tag).should be_nil
    end

    it "accepts optional hints" do
      router = Marten::DB::Router::BaseSpec::TestRouter.new
      tag = Tag.new(name: "coding", is_active: true)
      hints = Marten::DB::Router::Hints.new(instance: tag)

      router.db_for_write(Tag, hints).should be_nil
    end
  end

  describe "#allow_relation?" do
    it "returns nil by default" do
      router = Marten::DB::Router::BaseSpec::TestRouter.new
      tag_1 = Tag.new(name: "coding", is_active: true)
      tag_2 = Tag.new(name: "crystal", is_active: true)

      router.allow_relation?(tag_1, tag_2).should be_nil
    end

    it "accepts optional hints" do
      router = Marten::DB::Router::BaseSpec::TestRouter.new
      tag_1 = Tag.new(name: "coding", is_active: true)
      tag_2 = Tag.new(name: "crystal", is_active: true)
      hints = Marten::DB::Router::Hints.new(instance: tag_1)

      router.allow_relation?(tag_1, tag_2, hints).should be_nil
    end
  end

  describe "#allow_migrate?" do
    it "returns nil by default" do
      router = Marten::DB::Router::BaseSpec::TestRouter.new

      router.allow_migrate?("default", "app").should be_nil
    end

    it "accepts an optional model name and hints" do
      router = Marten::DB::Router::BaseSpec::TestRouter.new
      hints = Marten::DB::Router::Hints.new

      router.allow_migrate?("default", "app", "Tag", hints).should be_nil
    end
  end
end

module Marten::DB::Router::BaseSpec
  class TestRouter < Marten::DB::Router::Base
  end
end
