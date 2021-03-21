require "./spec_helper"

describe Marten::DB::Query::SQL::Query do
  describe "#add_query_node" do
    it "can add a new filter to an unfiltered query" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.add_query_node(Marten::DB::Query::Node.new(name__startswith: :c))
      query.count.should eq 2
      query.execute.should eq [tag_2, tag_3]
    end

    it "can add a new filter to an already filtered query" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.add_query_node(Marten::DB::Query::Node.new(name__startswith: :c))
      query.add_query_node(Marten::DB::Query::Node.new(name__endswith: :l))
      query.count.should eq 1
      query.execute.should eq [tag_2]
    end

    it "uses the exact predicate when a new filter without a specified predicate is added" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.add_query_node(Marten::DB::Query::Node.new(name: :crystal))
      query.count.should eq 1
      query.execute.should eq [tag_2]
    end

    it "uses the isnull predicate when a new filter for a nil value is added" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1", updated_by: user_2)
      Post.create!(author: user_2, title: "Post 2", updated_by: user_1)
      post_3 = Post.create!(author: user_1, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(updated_by: nil))
      query.count.should eq 1
      query.execute.should eq [post_3]
    end

    it "is able to process complex query nodes" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "typing", is_active: true)
      Tag.create!(name: "go", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.add_query_node(
        Marten::DB::Query::Node.new(is_active: true) & (
          (Marten::DB::Query::Node.new(name__startswith: "c") & Marten::DB::Query::Node.new(name__endswith: "l")) |
          Marten::DB::Query::Node.new(name: "typing")
        )
      )
      query.count.should eq 2
      query.execute.should eq [tag_2, tag_4]
    end

    it "is able to process query nodes with filters on relations" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1", updated_by: user_2)
      Post.create!(author: user_2, title: "Post 2", updated_by: user_1)
      post_3 = Post.create!(author: user_1, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(author__username: "foo"))
      query.count.should eq 2
      query.execute.to_set.should eq [post_1, post_3].to_set
    end

    it "is able to process query nodes with a direct filter on a relation model instance" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1", updated_by: user_2)
      Post.create!(author: user_2, title: "Post 2", updated_by: user_1)
      post_3 = Post.create!(author: user_1, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(author: user_1))
      query.count.should eq 2
      query.execute.to_set.should eq [post_1, post_3].to_set
    end

    it "is able to process query nodes with filters on reverse relations" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1", updated_by: user_2)
      Post.create!(author: user_2, title: "Post 2", updated_by: user_1)
      Post.create!(author: user_1, title: "Post 3")

      query_1 = Marten::DB::Query::SQL::Query(TestUser).new
      query_1.add_query_node(Marten::DB::Query::Node.new(posts__title__endswith: "1"))
      query_1.count.should eq 1
      query_1.execute.should eq [user_1]

      query_2 = Marten::DB::Query::SQL::Query(TestUser).new
      query_2.add_query_node(Marten::DB::Query::Node.new(posts__title: "unknown"))
      query_2.count.should eq 0
      query_2.execute.should be_empty
    end

    it "is able to process query nodes with filters on reverse relations plus relation fields" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1", updated_by: user_2)
      Post.create!(author: user_2, title: "Post 2", updated_by: user_1)
      Post.create!(author: user_1, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.add_query_node(Marten::DB::Query::Node.new(posts__updated_by: user_1))
      query.count.should eq 1
      query.execute.should eq [user_2]
    end

    it "raises if a query node targeting an unknown field is added" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      expect_raises(Marten::DB::Errors::InvalidField) do
        query.add_query_node(Marten::DB::Query::Node.new(unknown: "test"))
      end
    end

    it "raises if a query node targeting an unknown field on a relation is added" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1", updated_by: user_2)
      Post.create!(author: user_2, title: "Post 2", updated_by: user_1)
      Post.create!(author: user_1, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      expect_raises(Marten::DB::Errors::InvalidField) do
        query.add_query_node(Marten::DB::Query::Node.new(author__unknown: "foo"))
      end
    end

    it "raises if a query node targeting a known field followed by an unknown predicate is added" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      expect_raises(Marten::DB::Errors::InvalidField) do
        query.add_query_node(Marten::DB::Query::Node.new(name__unknown: "test"))
      end
    end

    it "raises if a query node targeting a known field followed by another known field is added" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      expect_raises(Marten::DB::Errors::InvalidField) do
        query.add_query_node(Marten::DB::Query::Node.new(name__id: "test"))
      end
    end
  end

  describe "#count" do
    it "returns the expected number of results for an unfiltered query" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::SQL::Query(Tag).new.count.should eq 3
    end

    it "returns the expected number of results for a filtered query" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.add_query_node(Marten::DB::Query::Node.new(name__startswith: :c))
      query_1.count.should eq 2

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.add_query_node(Marten::DB::Query::Node.new(name__startswith: "r"))
      query_2.count.should eq 1

      query_3 = Marten::DB::Query::SQL::Query(Tag).new
      query_3.add_query_node(Marten::DB::Query::Node.new(name__startswith: "x"))
      query_3.count.should eq 0
    end

    it "returns the expected number of results for a filtered query involving joins" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")
      Post.create!(author: user_1, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(author__username__startswith: "f"))
      query.count.should eq 2
    end

    it "returns the expected number of results for a sliced query" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.slice(1)
      query_1.count.should eq 2

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.slice(1, 1)
      query_2.count.should eq 1

      query_3 = Marten::DB::Query::SQL::Query(Tag).new
      query_3.slice(1, 2)
      query_3.count.should eq 2

      query_4 = Marten::DB::Query::SQL::Query(Tag).new
      query_4.slice(0)
      query_4.count.should eq 3
    end

    it "makes use of the specified DB connection" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.using(:other).create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.using = "other"
      query.count.should eq 1
    end
  end
end
