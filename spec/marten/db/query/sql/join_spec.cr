require "./spec_helper"

describe Marten::DB::Query::SQL::Join do
  describe "::new" do
    it "initializes a join node without children" do
      join = Marten::DB::Query::SQL::Join.new(
        1,
        Post.get_field("author_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        Post
      )
      join.children.should be_empty
    end
  end

  describe "#add_child" do
    it "adds a join node as a child to another join node" do
      parent_join = Marten::DB::Query::SQL::Join.new(
        1,
        ShowcasedPost.get_field("post_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        ShowcasedPost
      )
      child_join = Marten::DB::Query::SQL::Join.new(
        1,
        Post.get_field("author_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        Post
      )

      parent_join.add_child(child_join)

      parent_join.children.should eq [child_join]
      child_join.parent.should eq parent_join
    end
  end

  describe "#column_name" do
    it "returns a valid column name with the table prefix" do
      join = Marten::DB::Query::SQL::Join.new(
        1,
        Post.get_field("author_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        Post
      )
      join.column_name("username").should eq "t1.username"
    end
  end

  describe "#columns" do
    it "returns a array of all the parent and child column names" do
      parent_join = Marten::DB::Query::SQL::Join.new(
        1,
        ShowcasedPost.get_field("post_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        ShowcasedPost
      )
      child_join = Marten::DB::Query::SQL::Join.new(
        1,
        Post.get_field("author_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        Post
      )

      parent_join.add_child(child_join)

      parent_join.columns.should eq(
        Post.fields.map { |f| parent_join.column_name(f.db_column) } +
        TestUser.fields.map { |f| child_join.column_name(f.db_column) }
      )
    end
  end

  describe "#table_alias" do
    it "returns the alias of the table based on the join node ID" do
      parent_join = Marten::DB::Query::SQL::Join.new(
        1,
        ShowcasedPost.get_field("post_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        ShowcasedPost
      )
      child_join = Marten::DB::Query::SQL::Join.new(
        2,
        Post.get_field("author_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        Post
      )

      parent_join.add_child(child_join)

      parent_join.table_alias.should eq "t1"
      child_join.table_alias.should eq "t2"
    end
  end

  describe "#to_a" do
    it "returns a flat array of the node and its children" do
      parent_join = Marten::DB::Query::SQL::Join.new(
        1,
        ShowcasedPost.get_field("post_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        ShowcasedPost
      )
      child_join = Marten::DB::Query::SQL::Join.new(
        2,
        Post.get_field("author_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        Post
      )

      parent_join.add_child(child_join)

      parent_join.to_a.should eq [parent_join, child_join]
    end
  end

  describe "#to_sql" do
    it "returns the expected SQL for a single inner join" do
      join = Marten::DB::Query::SQL::Join.new(
        1,
        Post.get_field("author_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        Post
      )

      join.to_sql.should eq "INNER JOIN app_test_users t1 ON (posts.author_id = t1.id)"
    end

    it "returns the expected SQL for a single left outer join" do
      join = Marten::DB::Query::SQL::Join.new(
        1,
        Post.get_field("author_id"),
        Marten::DB::Query::SQL::JoinType::LEFT_OUTER,
        Post
      )

      join.to_sql.should eq "LEFT OUTER JOIN app_test_users t1 ON (posts.author_id = t1.id)"
    end

    it "returns the expected SQL for a join node with children" do
      parent_join = Marten::DB::Query::SQL::Join.new(
        1,
        ShowcasedPost.get_field("post_id"),
        Marten::DB::Query::SQL::JoinType::INNER,
        ShowcasedPost
      )
      child_join = Marten::DB::Query::SQL::Join.new(
        2,
        Post.get_field("author_id"),
        Marten::DB::Query::SQL::JoinType::LEFT_OUTER,
        Post
      )

      parent_join.add_child(child_join)

      parent_join.to_sql.should eq(
        "INNER JOIN posts t1 ON (app_showcased_posts.post_id = t1.id) " \
        "LEFT OUTER JOIN app_test_users t2 ON (t1.author_id = t2.id)"
      )
    end
  end
end
