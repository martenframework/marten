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
      user = TestUser.new(username: "jd") do |u|
        u.first_name = "John"
        u.last_name = "Doe"
      end

      user.username.should eq "jd"
      user.first_name.should eq "John"
      user.last_name.should eq "Doe"
      user.email.should be_nil
      user.persisted?.should be_false
    end

    it "allows to initialize model objects with a hash of field values" do
      user = TestUser.new({"username" => "jd", "first_name" => "John", "last_name" => "Doe"})
      user.username.should eq "jd"
      user.first_name.should eq "John"
      user.last_name.should eq "Doe"
      user.email.should be_nil
      user.persisted?.should be_false
    end

    it "allows to initialize model objects with a hash of field values and a block" do
      user = TestUser.new({"username" => "jd"}) do |u|
        u.first_name = "John"
        u.last_name = "Doe"
      end

      user.username.should eq "jd"
      user.first_name.should eq "John"
      user.last_name.should eq "Doe"
      user.email.should be_nil
      user.persisted?.should be_false
    end

    it "allows to initialize model objects with a named tuple of field values" do
      user = TestUser.new({username: "jd", first_name: "John", last_name: "Doe"})
      user.username.should eq "jd"
      user.first_name.should eq "John"
      user.last_name.should eq "Doe"
      user.email.should be_nil
      user.persisted?.should be_false
    end

    it "allows to initialize model objects with a named tuple of field values and a block" do
      user = TestUser.new({username: "jd"}) do |u|
        u.first_name = "John"
        u.last_name = "Doe"
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

    it "allows to assign nil as a specific field value" do
      post = Post.new(author_id: nil)
      post.author_id.should be_nil
      post.author.should be_nil
    end

    it "allows to assign nil as a specific related object value" do
      post = Post.new(author: nil)
      post.author_id.should be_nil
      post.author.should be_nil
    end

    it "is consistent when assigning both a related object and the corresponding ID" do
      user1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post = Post.new(author: user1, author_id: user2.id)

      post.author_id.should eq user1.id
      post.author.should eq user1
    end

    it "assigns default field values unless they are explicitly specified" do
      user_1 = TestUser.new
      user_1.is_admin.should be_false

      user_2 = TestUser.new(is_admin: true)
      user_2.is_admin.should be_true

      TestUser.create!(
        username: "jd",
        email: "jd@example.com",
        first_name: "John",
        last_name: "Doe",
        is_admin: true
      )
      TestUser.get!(username: "jd").is_admin.should be_true
    end

    it "runs after_initialize callbacks as expected" do
      obj = Marten::DB::ModelSpec::WithAfterInitializeCallbacks.new

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end
end

module Marten::DB::ModelSpec
  class WithAfterInitializeCallbacks < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :foo, :string, max_size: 255
    field :bar, :string, max_size: 255

    after_initialize :set_foo
    after_initialize :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end
end
