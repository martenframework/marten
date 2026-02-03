require "./spec_helper"
require "./polymorphic_spec/**"

describe Marten::DB::Field::Polymorphic do
  describe "#db_column" do
    it "returns nil" do
      field = Marten::DB::Field::Polymorphic.new(
        "polymorphic",
        "polymorphic_id",
        "polymorphic_type",
        [TestUser, Post]
      )

      field.db_column.should be_nil
    end
  end

  describe "#default" do
    it "returns nil" do
      field = Marten::DB::Field::Polymorphic.new(
        "polymorphic",
        "polymorphic_id",
        "polymorphic_type",
        [TestUser, Post]
      )

      field.default.should be_nil
    end
  end

  describe "#from_db" do
    it "returns nil" do
      field = Marten::DB::Field::Polymorphic.new(
        "polymorphic",
        "polymorphic_id",
        "polymorphic_type",
        [TestUser, Post]
      )

      field.from_db(42).should be_nil
    end
  end

  describe "#from_db_result_set" do
    it "returns nil" do
      field = Marten::DB::Field::Polymorphic.new(
        "polymorphic",
        "polymorphic_id",
        "polymorphic_type",
        [TestUser, Post]
      )

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 42") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#perform_validation" do
    it "does nothing" do
      field = Marten::DB::Field::Polymorphic.new(
        "polymorphic",
        "polymorphic_id",
        "polymorphic_type",
        [TestUser, Post],
        null: false,
        blank: false,
      )

      obj = TestUser.new(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      field.perform_validation(obj).should be_nil

      obj.errors.should be_empty
    end
  end

  describe "#relation?" do
    it "returns true" do
      field = Marten::DB::Field::Polymorphic.new(
        "polymorphic",
        "polymorphic_id",
        "polymorphic_type",
        [TestUser, Post],
      )

      field.relation?.should be_true
    end
  end

  describe "#relation_name" do
    it "returns the field ID" do
      field = Marten::DB::Field::Polymorphic.new(
        "my_polymorphic",
        "my_polymorphic_id",
        "my_polymorphic_type",
        [TestUser, Post],
      )

      field.relation_name.should eq "my_polymorphic"
    end
  end

  describe "#to_column" do
    it "returns nil" do
      field = Marten::DB::Field::Polymorphic.new(
        "polymorphic",
        "polymorphic_id",
        "polymorphic_type",
        [TestUser, Post],
      )

      field.to_column.should be_nil
    end
  end

  describe "#to_db" do
    it "returns nil" do
      field = Marten::DB::Field::Polymorphic.new(
        "polymorphic",
        "polymorphic_id",
        "polymorphic_type",
        [TestUser, Post],
      )

      field.to_db(42).should be_nil
    end
  end

  describe "::contribute_to_model" do
    with_installed_apps Marten::DB::Field::PolymorphicSpec::App

    it "generates a getter method for the relation" do
      article = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article
      )

      comment = Marten::DB::Field::PolymorphicSpec::Comment.get!(id: comment.id)

      comment.target.should eq article

      Marten::DB::Field::PolymorphicSpec::Comment.new.target.should be_nil
    end

    it "generates a bang getter method for the relation" do
      recipe = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is a recipe")
      comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: recipe
      )

      comment = Marten::DB::Field::PolymorphicSpec::Comment.get!(id: comment.id)

      comment.target!.should eq recipe

      expect_raises(NilAssertionError) { Marten::DB::Field::PolymorphicSpec::Comment.new.target! }
    end

    it "generates a getter? method for the relation" do
      article = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article
      )

      comment = Marten::DB::Field::PolymorphicSpec::Comment.get!(id: comment.id)

      comment.target?.should be_true

      Marten::DB::Field::PolymorphicSpec::Comment.new.target?.should be_false
    end

    it "generates a setter method for the relation" do
      article = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      recipe = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is a recipe")
      comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article
      )

      comment = Marten::DB::Field::PolymorphicSpec::Comment.get!(id: comment.id)

      comment.target = recipe

      comment.target.should eq recipe

      comment.target_type.should eq "Marten::DB::Field::PolymorphicSpec::Recipe"
      comment.target_id.should eq recipe.id!
    end

    it "generates a class getter method for the relation" do
      article = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article
      )

      comment.target_class.should eq Marten::DB::Field::PolymorphicSpec::Article

      comment.target_class.should eq Marten::DB::Field::PolymorphicSpec::Article

      Marten::DB::Field::PolymorphicSpec::Comment.new.target_class.should be_nil
    end

    it "generates a bang class getter method for the relation" do
      article = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article
      )

      comment.target_class!.should eq Marten::DB::Field::PolymorphicSpec::Article

      expect_raises(NilAssertionError) { Marten::DB::Field::PolymorphicSpec::Comment.new.target_class! }
    end

    it "generates a class method allowing to get all the records associated with a specific type" do
      article_1 = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      article_2 = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is another article")
      recipe_1 = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is a recipe")
      recipe_2 = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is another recipe")
      comment_1 = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article_1
      )
      comment_2 = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article_2
      )
      comment_3 = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: recipe_1
      )
      comment_4 = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: recipe_2
      )

      article_comments = Marten::DB::Field::PolymorphicSpec::Comment.with_article_target
      article_comments.to_a.should eq [comment_1, comment_2]

      recipe_comments = Marten::DB::Field::PolymorphicSpec::Comment.with_recipe_target
      recipe_comments.to_a.should eq [comment_3, comment_4]
    end

    it "generates a getter method returning the casted relation for a specific type" do
      article = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      recipe = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is a recipe")
      article_comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article
      )
      recipe_comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: recipe
      )

      article_comment.article_target.should eq article
      article_comment.recipe_target.should be_nil
      recipe_comment.article_target.should be_nil
      recipe_comment.recipe_target.should eq recipe
    end

    it "generates a bang getter method returning the casted relation for a specific type" do
      article = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      recipe = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is a recipe")
      article_comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article
      )
      recipe_comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: recipe
      )

      article_comment.article_target!.should eq article
      expect_raises(TypeCastError) { article_comment.recipe_target! }
      expect_raises(TypeCastError) { recipe_comment.article_target! }
      recipe_comment.recipe_target!.should eq recipe
    end

    it "generates a getter? method returning the casted relation for a specific type" do
      article = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      recipe = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is a recipe")
      article_comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article
      )
      recipe_comment = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: recipe
      )

      article_comment.article_target?.should be_true
      article_comment.recipe_target?.should be_false
      recipe_comment.article_target?.should be_false
      recipe_comment.recipe_target?.should be_true
    end

    it "properly forwards blank and null options to the underlying fields" do
      article = Marten::DB::Field::PolymorphicSpec::ArticleWithStringPk.create!(
        id: "123",
        title: "This is an article"
      )
      comment = Marten::DB::Field::PolymorphicSpec::AltComment.create!(
        text: "This is a comment",
        target: article
      )

      comment.class.get_field("target").blank?.should be_false
      comment.class.get_field("target").null?.should be_false
      comment.class.get_field("target_id").blank?.should be_false
      comment.class.get_field("target_id").null?.should be_false
      comment.class.get_field("target_type").blank?.should be_false
      comment.class.get_field("target_type").null?.should be_false
    end

    it "properly forwards index options to the underlying fields and creates the expected multi column index" do
      article = Marten::DB::Field::PolymorphicSpec::ArticleWithStringPk.create!(
        id: "123",
        title: "This is an article"
      )
      comment = Marten::DB::Field::PolymorphicSpec::AltComment.create!(
        text: "This is a comment",
        target: article
      )

      comment.class.get_field("target").index?.should be_true
      comment.class.get_field("target_id").index?.should be_true
      comment.class.get_field("target_type").index?.should be_true

      Marten::DB::Field::PolymorphicSpec::AltComment.db_indexes.size.should eq 1
      index = Marten::DB::Field::PolymorphicSpec::AltComment.db_indexes.first
      index.name.should eq "target_index"
      index.fields.map(&.id).should eq ["target_type", "target_id"]
    end

    it "properly forwards creates the expected unique constraint when the unique option is true" do
      article = Marten::DB::Field::PolymorphicSpec::ArticleWithStringPk.create!(
        id: "123",
        title: "This is an article"
      )
      comment = Marten::DB::Field::PolymorphicSpec::AltComment.create!(
        text: "This is a comment",
        target: article
      )

      comment.class.get_field("target").unique?.should be_true
      comment.class.get_field("target_id").unique?.should be_false
      comment.class.get_field("target_type").unique?.should be_false

      Marten::DB::Field::PolymorphicSpec::AltComment.db_unique_constraints.size.should eq 1
      unique_constraint = Marten::DB::Field::PolymorphicSpec::AltComment.db_unique_constraints.first
      unique_constraint.name.should eq "target_unique_constraint"
      unique_constraint.fields.map(&.id).should eq ["target_type", "target_id"]
    end

    it "properly sets up reverse relations on all the target models" do
      article_1 = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is an article")
      article_2 = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is another article")
      article_3 = Marten::DB::Field::PolymorphicSpec::Article.create!(title: "This is a third article")
      recipe_1 = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is a recipe")
      recipe_2 = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is another recipe")
      recipe_3 = Marten::DB::Field::PolymorphicSpec::Recipe.create!(title: "This is a third recipe")
      article_comment_1 = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article_1
      )
      article_comment_2 = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: article_2
      )
      recipe_comment_1 = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: recipe_1
      )
      recipe_comment_2 = Marten::DB::Field::PolymorphicSpec::Comment.create!(
        text: "This is a comment",
        target: recipe_2
      )

      article_1.comments.to_a.should eq [article_comment_1]
      article_2.comments.to_a.should eq [article_comment_2]
      article_3.comments.to_a.should be_empty
      recipe_1.comments.to_a.should eq [recipe_comment_1]
      recipe_2.comments.to_a.should eq [recipe_comment_2]
      recipe_3.comments.to_a.should be_empty

      built_comment = article_1.comments.build(text: "This is a comment")
      built_comment.target.should eq article_1
      built_comment.target_type.should eq "Marten::DB::Field::PolymorphicSpec::Article"
      built_comment.target_id.should eq article_1.id!
    end
  end
end
