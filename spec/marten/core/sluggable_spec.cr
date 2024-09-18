require "./spec_helper"

describe Marten::Core::Sluggable do
  describe "#generate_slug" do
    value = "Test Title 12354543435"
    max_size = 20
    g_slug = Marten::Core::SluggableSpec::SlugGenerator.new.generate_slug(value, max_size)

    it "removes non-alphanumeric characters" do
      value_with_special_chars = "Test@Title#123!"
      slug = Marten::Core::SluggableSpec::SlugGenerator.new.generate_slug(value_with_special_chars, max_size)
      slug.should eq("testtitle123")
    end

    it "handles emojis" do
      value_with_emojis = "🚀 TRAVEL & PLACES"
      slug = Marten::Core::SluggableSpec::SlugGenerator.new.generate_slug(value_with_emojis, max_size)
      slug.should eq("🚀-travel-places")
    end
    it "converts the string to lowercase" do
      g_slug.should eq("test-title-123545434")
    end

    it "replaces whitespace and hyphens with a single hyphen" do
      value_with_spaces_and_hyphens = "Test - Title   123"
      slug = Marten::Core::SluggableSpec::SlugGenerator.new.generate_slug(value_with_spaces_and_hyphens, max_size)
      slug.should eq("test-title-123")
    end

    it "strips leading and trailing hyphens and underscores" do
      value_with_hyphens = "-Test Title 123-"
      slug = Marten::Core::SluggableSpec::SlugGenerator.new.generate_slug(value_with_hyphens, max_size)
      slug.should eq("test-title-123")
    end

    it "removes non-ASCII characters" do
      value_with_non_ascii = "Test Títle 123"
      slug = Marten::Core::SluggableSpec::SlugGenerator.new.generate_slug(value_with_non_ascii, max_size)
      slug.should eq("test-títle-123")
    end

    it "limits the slug length to max_size" do
      g_slug.size.should eq(max_size)
    end

    it "does not exceed max_size even with long input" do
      long_value = "This is a very long title that should be truncated"
      slug = Marten::Core::SluggableSpec::SlugGenerator.new.generate_slug(long_value, max_size)
      slug.size.should be <= max_size
    end

    it "does not truncate the slug when max_size is large enough" do
      long_value = "This is a very long title that should not be truncated"
      slug = Marten::Core::SluggableSpec::SlugGenerator.new.generate_slug(long_value, 100)

      slug.should eq("this-is-a-very-long-title-that-should-not-be-truncated")
    end
  end
end

module Marten::Core::SluggableSpec
  class SlugGenerator
    include Marten::Core::Sluggable
  end
end
