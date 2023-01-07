require "./spec_helper"
require "./table_spec/app"

describe Marten::DB::Model::Table do
  with_installed_apps Marten::DB::Model::TableSpec::App

  describe "::finished" do
    it "allows abstract models without pk field" do
      Marten::DB::Model::TableSpec::AbstractModelWithoutPrimaryKey.fields.find(&.primary_key?).should be_nil
    end
  end

  describe "::inherited" do
    it "ensures that the model inherits its parent fields" do
      Marten::DB::Model::TableSpec::Article.fields.size.should eq 9
      Marten::DB::Model::TableSpec::Article.fields.map(&.id).should eq(
        [
          "created_at",
          "updated_at",
          "id",
          "author_id",
          "moderator_id",
          "title",
          "content",
          "tags",
          "additional_content",
        ]
      )
    end

    it "ensures that the model inherits its parent indexes" do
      Marten::DB::Model::TableSpec::Article.db_indexes.size.should eq 2
      Marten::DB::Model::TableSpec::Article.db_indexes.map(&.name).should eq(
        ["base_author_title_index", "other_author_title_index"]
      )
    end

    it "ensures that the model inherits its parent unique constraints" do
      Marten::DB::Model::TableSpec::Article.db_unique_constraints.size.should eq 2
      Marten::DB::Model::TableSpec::Article.db_unique_constraints.map(&.name).should eq(
        ["base_author_title_constraint", "other_author_title_constraint"]
      )
    end

    it "produces models that can be used to create records" do
      author = Marten::DB::Model::TableSpec::Author.create!(name: "Author")
      moderator = Marten::DB::Model::TableSpec::Author.create!(name: "Moderator")

      article = Marten::DB::Model::TableSpec::Article.create!(
        title: "Article 1",
        content: "Article content 1",
        additional_content: "Article additional content 1",
        author: author,
        moderator: moderator
      )
      article.persisted?.should be_true

      Marten::DB::Model::TableSpec::Article.all.to_a.should eq [article]
    end

    it "produces models that can be used to create records with many to one fields" do
      author = Marten::DB::Model::TableSpec::Author.create!(name: "Author")
      moderator = Marten::DB::Model::TableSpec::Author.create!(name: "Moderator")

      article = Marten::DB::Model::TableSpec::Article.create!(
        title: "Article 1",
        content: "Article content 1",
        additional_content: "Article additional content 1",
        author: author,
        moderator: moderator
      )
      article.persisted?.should be_true

      author.articles.to_a.should eq [article]
    end

    it "produces models that can be used to create records with one to one fields" do
      author = Marten::DB::Model::TableSpec::Author.create!(name: "Author")
      moderator = Marten::DB::Model::TableSpec::Author.create!(name: "Moderator")

      article = Marten::DB::Model::TableSpec::Article.create!(
        title: "Article 1",
        content: "Article content 1",
        additional_content: "Article additional content 1",
        author: author,
        moderator: moderator
      )
      article.persisted?.should be_true

      moderator.moderated_article.should eq article
    end

    it "produces models that can be used to create records with many many one fields" do
      author = Marten::DB::Model::TableSpec::Author.create!(name: "Author")
      moderator = Marten::DB::Model::TableSpec::Author.create!(name: "Moderator")

      tag_1 = Marten::DB::Model::TableSpec::Tag.create!(name: "t1")
      tag_2 = Marten::DB::Model::TableSpec::Tag.create!(name: "t2")

      article = Marten::DB::Model::TableSpec::Article.create!(
        title: "Article 1",
        content: "Article content 1",
        additional_content: "Article additional content 1",
        author: author,
        moderator: moderator
      )
      article.persisted?.should be_true

      article.tags.add(tag_1)
      article.tags.add(tag_2)

      article.tags.to_a.should eq [tag_1, tag_2]
      tag_1.articles.to_a.should eq [article]
    end
  end

  describe "::db_index" do
    it "allows to configure new index" do
      indexes = Post.db_indexes
      indexes.size.should eq 1
      indexes[0].name.should eq "author_title_index"
      indexes[0].fields.size.should eq 2
      indexes[0].fields[0].id.should eq "author_id"
      indexes[0].fields[1].id.should eq "title"
    end

    it "raises if the passed field does not correspond to any of the model's fields" do
      expect_raises(
        Marten::DB::Errors::UnknownField,
        "Unknown field 'unknown' in index definition"
      ) do
        Post.db_index("new_unique", ["unknown", "author"])
      end
    end
  end

  describe "::db_indexes" do
    it "returns an empty array if no indexes are defined" do
      TestUser.db_indexes.should be_empty
    end

    it "returns an array of the configured indexes" do
      indexes = Post.db_indexes
      indexes.size.should eq 1
      indexes[0].name.should eq "author_title_index"
      indexes[0].fields.size.should eq 2
      indexes[0].fields[0].id.should eq "author_id"
      indexes[0].fields[1].id.should eq "title"
    end
  end

  describe "::db_table" do
    it "returns the name of the model table based on the class name by default" do
      TestUser.db_table.should eq "app_test_user"
    end

    it "does not append a s characters if model names already end by one" do
      PostTags.db_table.should eq "app_post_tags"
    end

    it "returns the configured table name if applicable" do
      Post.db_table.should eq "posts"
    end
  end

  describe "::db_table(name)" do
    it "allows to configure the model table name" do
      Post.db_table.should eq "posts"
    end
  end

  describe "::db_unique_constraint" do
    it "allows to configure new unique constraints" do
      unique_constraints = Post.db_unique_constraints
      unique_constraints.size.should eq 1
      unique_constraints[0].name.should eq "author_title_constraint"
      unique_constraints[0].fields.size.should eq 2
      unique_constraints[0].fields[0].id.should eq "author_id"
      unique_constraints[0].fields[1].id.should eq "title"
    end

    it "raises if the passed field does not correspond to any of the model's fields" do
      expect_raises(
        Marten::DB::Errors::UnknownField,
        "Unknown field 'unknown' in unique constraint definition"
      ) do
        Post.db_unique_constraint("new_unique", ["unknown", "author"])
      end
    end
  end

  describe "::db_unique_constraints" do
    it "returns an empty array if no unique constraints are defined" do
      TestUser.db_unique_constraints.should be_empty
    end

    it "returns an array of the configured unique constraints when unique constraints are defined" do
      unique_constraints = Post.db_unique_constraints
      unique_constraints.size.should eq 1
      unique_constraints[0].name.should eq "author_title_constraint"
      unique_constraints[0].fields.size.should eq 2
      unique_constraints[0].fields[0].id.should eq "author_id"
      unique_constraints[0].fields[1].id.should eq "title"
    end
  end

  describe "::fields" do
    it "returns the field instances associated with the considered model class" do
      Tag.fields.size.should eq 3
      Tag.fields.map(&.id).should eq ["id", "name", "is_active"]
    end
  end

  describe "::get_field" do
    it "allows to retrieve a specific model fields from an ID string" do
      field = Tag.get_field("name")
      field.should be_a Marten::DB::Field::String
      field.id.should eq "name"
    end

    it "allows to retrieve a specific model fields from an ID symbol" do
      field = Tag.get_field(:name)
      field.should be_a Marten::DB::Field::String
      field.id.should eq "name"
    end

    it "allows to retrieve a specific model fields from a relation name" do
      field = Post.get_field(:author)
      field.should be_a Marten::DB::Field::ManyToOne
      field.id.should eq "author_id"
    end

    it "raises if the field cannot be found" do
      expect_raises(Marten::DB::Errors::UnknownField) do
        Tag.get_field(:unknown)
      end
    end
  end

  describe "::with_timestamp_fields" do
    it "adds the expected fields to the model" do
      created_at_field = Marten::DB::Model::TableSpec::BaseArticle.get_field("created_at")
      created_at_field.should be_a Marten::DB::Field::DateTime
      created_at_field.as(Marten::DB::Field::DateTime).auto_now_add?.should be_true
      created_at_field.as(Marten::DB::Field::DateTime).auto_now?.should be_false

      updated_at_field = Marten::DB::Model::TableSpec::BaseArticle.get_field("updated_at")
      updated_at_field.should be_a Marten::DB::Field::DateTime
      updated_at_field.as(Marten::DB::Field::DateTime).auto_now?.should be_true
      updated_at_field.as(Marten::DB::Field::DateTime).auto_now_add?.should be_false
    end
  end

  describe "#get_field_value" do
    it "returns the value of a specific model instance field" do
      tag = Tag.new(name: "crystal")
      tag.get_field_value("name").should eq "crystal"
    end

    it "can support field names expressed as symbols" do
      tag = Tag.new(name: "crystal")
      tag.get_field_value(:name).should eq "crystal"
    end

    it "raises if the field cannot be found" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnknownField) do
        tag.get_field_value(:unknown)
      end
    end
  end

  describe "#pk" do
    it "returns the primary key field value" do
      tag = Marten::DB::Model::TableSpec::Tag.create!(name: "crystal")

      tag.pk.should_not be_nil
      tag.pk.should eq tag.id
    end

    it "returns the raw field value for a relationship field" do
      tag = Marten::DB::Model::TableSpec::Tag.create!(name: "crystal")
      wrapping_tag = Marten::DB::Model::TableSpec::WrappingTag.create!(tag: tag, details: "Test")

      wrapping_tag.pk.should_not be_nil
      wrapping_tag.pk.should eq tag.pk
    end

    it "returns nil if the primary key field has no value" do
      tag = Marten::DB::Model::TableSpec::Tag.new

      tag.pk.should be_nil
    end
  end

  describe "#pk!" do
    it "returns the primary key field value" do
      tag = Marten::DB::Model::TableSpec::Tag.create!(name: "crystal")

      tag.pk!.should_not be_nil
      tag.pk!.should eq tag.id
    end

    it "raises a NilAssertionError if the primary key field has no value" do
      tag = Marten::DB::Model::TableSpec::Tag.new

      expect_raises(NilAssertionError) { tag.pk! }
    end
  end

  describe "#pk=" do
    it "allows to set the primary key field value" do
      tag = Marten::DB::Model::TableSpec::Tag.create!(name: "crystal")

      tag.pk = 42
      tag.pk.should eq 42
    end
  end

  describe "#set_field_value" do
    it "allows to set the value of a specific model instance field" do
      tag = Tag.new(name: "crystal")
      tag.set_field_value("name", "ruby")
      tag.name.should eq "ruby"
    end

    it "can support field names expressed as symbols" do
      tag = Tag.new(name: "crystal")
      tag.set_field_value(:name, "ruby")
      tag.name.should eq "ruby"
    end

    it "raises if the field cannot be found" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnknownField) do
        tag.set_field_value(:unknown, "test")
      end
    end

    it "raises if the value type is invalid for the considered field type" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        tag.set_field_value(:name, 42)
      end
    end
  end

  describe "#set_field_values" do
    it "allows to set the value of specific model instance fields from keyword arguments" do
      tag = Tag.new(name: "crystal", is_active: false)
      tag.set_field_values(name: "updated", is_active: true)
      tag.name.should eq "updated"
      tag.is_active.should be_true
    end

    it "allows to set the value of specific model instance fields from a hash" do
      tag = Tag.new(name: "crystal", is_active: false)
      tag.set_field_values({"name" => "updated", "is_active" => true})
      tag.name.should eq "updated"
      tag.is_active.should be_true
    end

    it "allows to set the value of specific model instance fields from a named tuple" do
      tag = Tag.new(name: "crystal", is_active: false)
      tag.set_field_values({name: "updated", is_active: true})
      tag.name.should eq "updated"
      tag.is_active.should be_true
    end

    it "raises if a field cannot be found" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnknownField) do
        tag.set_field_values(name: "updated", unknown: "test")
      end
    end

    it "raises if a value type is invalid for the considered field type" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        tag.set_field_values(name: 42, is_active: true)
      end
    end
  end

  describe "#to_s" do
    it "returns the expected model instance representation" do
      tag = Tag.create!(name: "crystal", is_active: true)
      tag.to_s.should eq "#<Tag:0x#{tag.object_id.to_s(16)} id: #{tag.id}, name: \"crystal\", is_active: true>"
    end
  end

  describe "#inspect" do
    it "returns the expected model instance representation" do
      tag = Tag.create!(name: "crystal", is_active: true)
      tag.inspect.should eq "#<Tag:0x#{tag.object_id.to_s(16)} id: #{tag.id}, name: \"crystal\", is_active: true>"
    end
  end
end
