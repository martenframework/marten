require "./spec_helper"
require "./slug_spec/**"

describe Marten::DB::Field::Slug do
  describe "#max_size" do
    it "returns 50 by default" do
      field = Marten::DB::Field::Slug.new("my_field")
      field.max_size.should eq 50
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::Slug.new("my-slug", db_column: "my_field_col")
      column = field.to_column
      column.should be_a Marten::DB::Management::Column::String
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_true
      column.max_size.should eq 50
      column.default.should be_nil
    end
  end

  describe "slugify" do
    with_installed_apps Marten::DB::Field::SlugSpec::App

    it "automatically generates a slug from the title field and assigns it to the slug field if no slug is given" do
      article = Marten::DB::Field::SlugSpec::Article.new(title: "My First Article")

      article.save

      article.slug.not_nil!.starts_with?("my-first-article-").should be_true
    end

    it "automatically generating a slug does not raise an error", tags: "What" do
      article = Marten::DB::Field::SlugSpec::Article.new(title: "My First Article")

      article.save

      article.errors.size.should eq(0)
    end

    it "automatically generating a slug does not raise an error", tags: "What" do
      article = Marten::DB::Field::SlugSpec::Article.new(title: "My First Article", slug: "")

      article.save

      article.errors.size.should eq(0)
    end

    it "truncates the slug to fit the max size of 50 and appends a random suffix" do
      article = Marten::DB::Field::SlugSpec::Article.new(
        title: "My First Article: Exploring the Intricacies of Quantum Mechanics"
      )

      article.save

      article.slug.not_nil!.includes?("quantum").should_not be_true
      article.slug.not_nil!.size.should eq(50)
    end

    it "does not truncate the slug if max size is greater than the string length" do
      article = Marten::DB::Field::SlugSpec::ArticleLongSlug.new(
        title: "My First Article: Exploring the Intricacies of Quantum Mechanics"
      )

      article.save

      article.slug.not_nil!.includes?("quantum").should be_true
    end

    it "removes non-ASCII characters and slugifies the title" do
      article = Marten::DB::Field::SlugSpec::Article.new(title: "Überraschungsmoment")

      article.save

      article.slug.not_nil!.starts_with?("berraschungsmoment").should be_true
    end

    it "removes emoji and special characters and slugifies the title" do
      article = Marten::DB::Field::SlugSpec::Article.new(title: "🚀 TRAVEL & PLACES")

      article.save

      article.slug.not_nil!.starts_with?("travel-places").should be_true
    end

    it "trims leading and trailing whitespace and slugifies the title" do
      article = Marten::DB::Field::SlugSpec::Article.new(title: "   Test   Article   ")

      article.save

      article.slug.not_nil!.starts_with?("test-article").should be_true
    end

    it "retains a custom slug if provided" do
      article = Marten::DB::Field::SlugSpec::Article.new(title: "My First Article", slug: "custom-slug")

      article.save

      article.slug.not_nil!.should eq("custom-slug")
    end

    it "uses a custom slug generator function when provided" do
      article = Marten::DB::Field::SlugSpec::ArticleWithCustomSlugGenerator.new(title: "My First Article")

      article.save

      article.slug.not_nil!.should eq("MY_FIRST_ARTICLE")
    end
  end

  describe "#validate" do
    it "does not add an error to the record if the string contains a valid slug" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug")
      field.validate(obj, "th1s-1s-val1d-slug")

      obj.errors.size.should eq 0
    end

    it "adds an error to the record if the string contains two consecutive dashes" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug")
      field.validate(obj, "th1s-1s-not--val1d-slug")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "my-slug"
      obj.errors.first.message.should eq "Enter a valid slug."
    end

    it "adds an error to the record if the string starts with a non alphanumeric character" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug", null: false)
      field.validate(obj, "-foo")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "my-slug"
      obj.errors.first.message.should eq "Enter a valid slug."
    end

    it "adds an error to the record if the string ends with a non alphanumeric character" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug", null: false)
      field.validate(obj, "foo-")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "my-slug"
      obj.errors.first.message.should eq "Enter a valid slug."
    end

    it "adds an error to the record if the string contains non-ascii characters" do
      obj = Tag.new(name: nil)

      field = Marten::DB::Field::Slug.new("my-slug", null: false)
      field.validate(obj, "foo-✓-bar")

      obj.errors.size.should eq 1
      obj.errors.first.field.should eq "my-slug"
      obj.errors.first.message.should eq "Enter a valid slug."
    end
  end
end
