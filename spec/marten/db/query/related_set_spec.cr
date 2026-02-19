require "./spec_helper"

describe Marten::DB::Query::RelatedSet do
  describe "#all" do
    it "is scoped to the related field target when considering a many-to-one relation" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_1, title: "Post 3")

      qset = Marten::DB::Query::RelatedSet(Post).new(user_1, "author_id")

      qset.all.to_set.should eq(Set{post_1, post_3})
    end

    it "is scoped to the related field target when considering a polymorphic relation" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")

      comment_1 = Comment.create!(target: post_1, text: "Comment 1")
      Comment.create!(target: post_2, text: "Comment 2") # another unrelated comment
      comment_3 = Comment.create!(target: post_1, text: "Comment 3")

      qset = Marten::DB::Query::RelatedSet(Comment).new(post_1, "target")

      qset.all.to_set.should eq(Set{comment_1, comment_3})
    end
  end

  describe "#build" do
    it "initializes a new record with the related field set" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      qset = Marten::DB::Query::RelatedSet(Post).new(user, "author_id")

      new_post = qset.build(title: "Post")

      new_post.persisted?.should be_false
      new_post.author.should eq user
      new_post.title.should eq "Post"
    end

    it "initializes a new record with the related field set when a block is used" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      qset = Marten::DB::Query::RelatedSet(Post).new(user, "author_id")

      new_post = qset.build do |p|
        p.title = "Post"
      end

      new_post.persisted?.should be_false
      new_post.author.should eq user
      new_post.title.should eq "Post"
    end
  end

  describe "#create" do
    it "creates a new record with the related field set" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      qset = Marten::DB::Query::RelatedSet(Post).new(user, "author_id")

      new_post = qset.create(title: "Post")

      new_post.valid?.should be_true
      new_post.persisted?.should be_true
      new_post.author.should eq user
    end

    it "creates a new record with the related field set when a block is used" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      qset = Marten::DB::Query::RelatedSet(Post).new(user, "author_id")

      new_post = qset.create do |p|
        p.title = "Post"
      end

      new_post.valid?.should be_true
      new_post.persisted?.should be_true
      new_post.author.should eq user
    end
  end

  describe "#create!" do
    it "creates a new record with the related field set" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      qset = Marten::DB::Query::RelatedSet(Post).new(user, "author_id")

      new_post = qset.create!(title: "Post")

      new_post.valid?.should be_true
      new_post.persisted?.should be_true
      new_post.author.should eq user
    end

    it "creates a new record with the related field set when a block is used" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      qset = Marten::DB::Query::RelatedSet(Post).new(user, "author_id")

      new_post = qset.create! do |p|
        p.title = "Post"
      end

      new_post.valid?.should be_true
      new_post.persisted?.should be_true
      new_post.author.should eq user
    end
  end

  describe "#fetch" do
    it "assigns the related object if assign_related is explicitly set to true" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Post 1")

      qset = Marten::DB::Query::RelatedSet(Post).new(user, "author_id", assign_related: true)

      qset[0].get_related_object_variable(:author).should eq user
    end

    it "does not assign the related object when assign_related is explicitly set to false" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Post 1")

      qset = Marten::DB::Query::RelatedSet(Post).new(user, "author_id", assign_related: false)

      qset[0].get_related_object_variable(:author).should be_nil
    end

    it "does not assign the related object when assign_related is left as the default value (false)" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Post 1")

      qset = Marten::DB::Query::RelatedSet(Post).new(user, "author_id")

      qset[0].get_related_object_variable(:author).should be_nil
    end
  end
end
