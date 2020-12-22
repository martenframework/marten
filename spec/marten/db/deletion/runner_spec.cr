require "./spec_helper"

describe Marten::DB::Deletion::Runner do
  describe "::new" do
    it "initializes a deletion runner for a specific DB connection only" do
      Tag.using(:other).create!(name: "coding", is_active: true)
      Tag.using(:other).create!(name: "crystal", is_active: true)
      tag = Tag.create!(name: "ruby", is_active: true)

      deletion = Marten::DB::Deletion::Runner.new(Marten::DB::Connection.default)
      deletion.add(tag)
      deletion.execute

      Tag.all.exists?.should be_false
      Tag.using(:other).all.size.should eq 2
    end
  end

  describe "#add" do
    it "can register a specific model instance for deletion" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)

      deletion = Marten::DB::Deletion::Runner.new(Marten::DB::Connection.default)
      deletion.add(tag_3)
      deletion.execute

      Tag.all.size.should eq 2
      Tag.all.map(&.id).to_set.should eq [tag_1.id, tag_2.id].to_set
    end

    it "can register a specific queryset for deletion" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)

      deletion = Marten::DB::Deletion::Runner.new(Marten::DB::Connection.default)
      deletion.add(Tag.filter { q(name: "coding") | q(name: "crystal") })
      deletion.execute

      Tag.all.map(&.id).should eq [tag_3.id]
    end

    it "supports model instances whose relations are configured to use cascade on_delete" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      Post.create!(author: user_1, title: "Post 3")

      deletion = Marten::DB::Deletion::Runner.new(Marten::DB::Connection.default)
      deletion.add(user_1)
      deletion.execute

      TestUser.all.map(&.id).should eq [user_2.id]
      Post.all.map(&.id).should eq [post_2.id]
    end

    it "supports model instances whose relations are configured to use set_null on_delete" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, updated_by: user_3, title: "Post 2")
      post_3 = Post.create!(author: user_1, updated_by: user_3, title: "Post 3")

      deletion = Marten::DB::Deletion::Runner.new(Marten::DB::Connection.default)
      deletion.add(user_3)
      deletion.execute

      TestUser.all.map(&.id).to_set.should eq [user_1.id, user_2.id].to_set
      Post.all.size.should eq 3
      post_2.reload.updated_by.should be_nil
      post_2.reload.updated_by_id.should be_nil
      post_3.reload.updated_by.should be_nil
      post_3.reload.updated_by_id.should be_nil
    end

    it "supports model instances whose relations are configured to use protect on_delete" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_1, title: "Post 3")

      ProtectedPost.create!(post: post_1)
      ProtectedPost.create!(post: post_2)
      ProtectedPost.create!(post: post_3)

      deletion = Marten::DB::Deletion::Runner.new(Marten::DB::Connection.default)

      expect_raises(Marten::DB::Errors::ProtectedRecord) do
        deletion.add(user_1)
      end

      TestUser.all.size.should eq 2
      Post.all.size.should eq 3
      ProtectedPost.all.size.should eq 3
    end

    it "follows cascade on_delete reverse relations" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_1, title: "Post 3")

      ShowcasedPost.create!(post: post_1)
      showcased_post_2 = ShowcasedPost.create!(post: post_2)
      ShowcasedPost.create!(post: post_3)

      deletion = Marten::DB::Deletion::Runner.new(Marten::DB::Connection.default)
      deletion.add(user_1)
      deletion.execute

      TestUser.all.map(&.id).to_set.should eq [user_2.id].to_set
      Post.all.map(&.id).should eq [post_2.id]
      ShowcasedPost.all.map(&.id).should eq [showcased_post_2.id]
    end

    it "is able to process many deletions in the right order" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)

      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_1, title: "Post 3")
      post_4 = Post.create!(author: user_2, title: "Post 4")

      ShowcasedPost.create!(post: post_1)
      ShowcasedPost.create!(post: post_2)
      ShowcasedPost.create!(post: post_3)

      deletion = Marten::DB::Deletion::Runner.new(Marten::DB::Connection.default)
      deletion.add(post_1)
      deletion.add(post_2)
      deletion.add(user_1)
      deletion.add(tag_1)
      deletion.add(tag_3)
      deletion.execute

      TestUser.all.map(&.id).to_set.should eq [user_2.id].to_set
      Post.all.map(&.id).should eq [post_4.id]
      ShowcasedPost.all.size.should eq 0
      Tag.all.map(&.id).should eq [tag_2.id]
    end
  end
end
