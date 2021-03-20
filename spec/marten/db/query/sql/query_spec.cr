require "./spec_helper"

describe Marten::DB::Query::SQL::Query do
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

    it "makes use of the specified DB connection" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.using(:other).create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.using = "other"
      query_1.count.should eq 1
    end
  end
end
