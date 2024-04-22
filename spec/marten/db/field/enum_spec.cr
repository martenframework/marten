require "./spec_helper"
require "./enum_spec/**"

describe Marten::DB::Field::Enum do
  describe "#default" do
    it "returns nil if no default value is set" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      field.default.should be_nil
    end

    it "returns the default value if set" do
      field = Marten::DB::Field::Enum.new(
        "my_field",
        enum_values: ["RED", "GREEN", "BLUE"],
        default: Marten::DB::Field::EnumSpec::Color::GREEN
      )

      field.default.should eq "GREEN"
    end
  end

  describe "#from_db" do
    it "returns a string if the value is a string" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      field.from_db("foo").should eq "foo"
    end

    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      field.from_db(nil).should be_nil
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.from_db(true)
      end
    end
  end

  describe "#from_db_result_set" do
    it "is able to read an string value from a DB result set" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 'hello'") do |rs|
          rs.each do
            value = field.from_db_result_set(rs)
            value.should be_a String
            value.should eq "hello"
          end
        end
      end
    end

    it "is able to read a null value from a DB result set" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT NULL") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#to_column" do
    it "returns the expected column" do
      field = Marten::DB::Field::Enum.new("my_field", db_column: "my_field_col", enum_values: ["RED", "GREEN", "BLUE"])

      column = field.to_column
      column.should be_a Marten::DB::Management::Column::Enum
      column.name.should eq "my_field_col"
      column.primary_key?.should be_false
      column.null?.should be_false
      column.unique?.should be_false
      column.index?.should be_false
      column.values.should eq ["RED", "GREEN", "BLUE"]
      column.default.should be_nil
    end

    it "properly forwards the default value if applicable" do
      field = Marten::DB::Field::Enum.new(
        "my_field",
        enum_values: ["RED", "GREEN", "BLUE"],
        default: Marten::DB::Field::EnumSpec::Color::GREEN
      )

      column = field.to_column
      column.default.should eq "GREEN"
    end
  end

  describe "#to_db" do
    it "returns nil if the value is nil" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      field.to_db(nil).should be_nil
    end

    it "returns a string value if the initial value is a string" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      field.to_db("hello").should eq "hello"
    end

    it "returns a string value if the initial value is a symbol" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      field.to_db(:hello).should eq "hello"
    end

    it "raises UnexpectedFieldValue if the value is not supported" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        field.to_db(["foo", "bar"])
      end
    end
  end

  describe "#values" do
    it "returns the enum values" do
      field = Marten::DB::Field::Enum.new("my_field", enum_values: ["RED", "GREEN", "BLUE"])

      field.values.should eq ["RED", "GREEN", "BLUE"]
    end
  end

  describe "::contribute_to_model" do
    with_installed_apps Marten::DB::Field::EnumSpec::App

    it "configures a field that can be saved" do
      article = Marten::DB::Field::EnumSpec::Article.new
      article.title = "Hello, world!"
      article.category = Marten::DB::Field::EnumSpec::Article::Category::BLOG
      article.save!
    end

    it "properly generates a #<field_name> getter" do
      article_1 = Marten::DB::Field::EnumSpec::Article.create!(
        title: "Hello, world!",
        category: Marten::DB::Field::EnumSpec::Article::Category::BLOG
      )
      article_1.category.should eq Marten::DB::Field::EnumSpec::Article::Category::BLOG

      article_2 = Marten::DB::Field::EnumSpec::Article.new
      article_2.category.should be_nil
    end

    it "properly generates a #<field_name>! getter" do
      article_1 = Marten::DB::Field::EnumSpec::Article.create!(
        title: "Hello, world!",
        category: Marten::DB::Field::EnumSpec::Article::Category::BLOG
      )
      article_1.category!.should eq Marten::DB::Field::EnumSpec::Article::Category::BLOG

      article_2 = Marten::DB::Field::EnumSpec::Article.new
      expect_raises(NilAssertionError) { article_2.category! }
    end

    it "properly generates a #<field_name>? getter" do
      article_1 = Marten::DB::Field::EnumSpec::Article.create!(
        title: "Hello, world!",
        category: Marten::DB::Field::EnumSpec::Article::Category::BLOG
      )
      article_1.category?.should be_true

      article_2 = Marten::DB::Field::EnumSpec::Article.new
      article_2.category?.should be_false
    end

    it "properly generates a #<field_name>=(value) setter that takes enum values" do
      article = Marten::DB::Field::EnumSpec::Article.new

      article.category = Marten::DB::Field::EnumSpec::Article::Category::BLOG
      article.category.should eq Marten::DB::Field::EnumSpec::Article::Category::BLOG
      article.raw_category.should eq "BLOG"
    end

    it "properly generates a #<field_name>=(value) setter that takes string values" do
      article = Marten::DB::Field::EnumSpec::Article.new

      article.category = "BLOG"
      article.category.should eq Marten::DB::Field::EnumSpec::Article::Category::BLOG
      article.raw_category.should eq "BLOG"

      expect_raises(ArgumentError) do
        article.category = "FOO"
      end
    end

    it "properly generates a #<field_name>=(value) setter that takes nil values" do
      article = Marten::DB::Field::EnumSpec::Article.new

      article.category = Marten::DB::Field::EnumSpec::Article::Category::BLOG
      article.category.should eq Marten::DB::Field::EnumSpec::Article::Category::BLOG
      article.raw_category.should eq "BLOG"

      article.category = nil
      article.category.should be_nil
      article.raw_category.should be_nil
    end
  end
end

module Marten::DB::Field::EnumSpec
  enum Color
    RED
    GREEN
    BLUE
  end
end
