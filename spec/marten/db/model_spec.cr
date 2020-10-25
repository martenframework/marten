require "./spec_helper"

describe Marten::DB::Model do
  describe "::new" do
    it "allows to initialize model objects without any fields specified" do
      user = TestUser.new
      user.username.should be_nil
      user.persisted?.should be_false
    end

    it "allows to initialize model objects with specific field values" do
      user = TestUser.new(username: "jd", first_name: "John", last_name: "Doe")
      user.username.should eq "jd"
      user.first_name.should eq "John"
      user.last_name.should eq "Doe"
      user.email.should be_nil
      user.persisted?.should be_false
    end

    it "allows to initialize model objects with specific field values in a block" do
      user = TestUser.new(username: "jd") do |user|
        user.first_name = "John"
        user.last_name = "Doe"
      end

      user.username.should eq "jd"
      user.first_name.should eq "John"
      user.last_name.should eq "Doe"
      user.email.should be_nil
      user.persisted?.should be_false
    end

    it "allows to initialize model objects with related persisted objects" do
      user = TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.new(author: user)
      post_1.author_id.should eq user.id
      post_1.author.should eq user

      post_2 = Post.new(author_id: user.id)
      post_2.author_id.should eq user.id
      post_2.author.should eq user
    end

    it "allows to initialize model objects with related non-persisted objects" do
      user = TestUser.new(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")

      post = Post.new(author: user)
      post.author_id.should be_nil
      post.author.should eq user
    end

    it "is consistent when assigning both a relatd object and the corresponding ID" do
      user1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post = Post.new(author: user1, author_id: user2.id)

      post.author_id.should eq user2.id
      post.author.should eq user2
    end
  end
end
