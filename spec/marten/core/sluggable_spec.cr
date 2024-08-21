require "./spec_helper"

describe Marten::Core::Sluggable do
  describe ".generate_slug" do
    value = "Test Title 123"
    max_size = 20
    slug = Marten::Core::Sluggable.generate_slug(value, max_size)

    it "removes non-alphanumeric characters" do
      value_with_special_chars = "Test@Title#123!"
      slug = Marten::Core::Sluggable.generate_slug(value_with_special_chars, max_size)
      slug.starts_with?("testtitle12-").should be_true
    end

    it "converts the string to lowercase" do
      slug.starts_with?("testtitle12-").should be_true
    end

    it "replaces whitespace and hyphens with a single hyphen" do
      value_with_spaces_and_hyphens = "Test - Title   123"
      slug = Marten::Core::Sluggable.generate_slug(value_with_spaces_and_hyphens, max_size)
      slug.starts_with?("test-title-").should be_true
    end

    it "strips leading and trailing hyphens and underscores" do
      value_with_hyphens = "-Test Title 123-"
      slug = Marten::Core::Sluggable.generate_slug(value_with_hyphens, max_size)
      slug.starts_with?("test-title-").should be_true
    end

    it "removes non-ASCII characters" do
      value_with_non_ascii = "Test Títle 123"
      slug = Marten::Core::Sluggable.generate_slug(value_with_non_ascii, max_size)
      slug.starts_with?("test-ttle-1-").should be_true
    end

    it "limits the slug length to max_size" do
      slug.size.should eq(max_size)
    end

    it "does not exceed max_size even with long input" do
      long_value = "This is a very long title that should be truncated"
      slug = Marten::Core::Sluggable.generate_slug(long_value, max_size)
      slug.size.should eq(max_size)
    end

    it "does not truncate the slug when max_size is large enough" do
      long_value = "This is a very long title that should not be truncated"
      slug = Marten::Core::Sluggable.generate_slug(long_value, 100)

      slug.starts_with?("this-is-a-very-long-title-that-should-not-be-truncated").should be_true
    end
  end
end
