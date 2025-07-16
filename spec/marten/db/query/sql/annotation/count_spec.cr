require "./spec_helper"

describe Marten::DB::Query::SQL::Annotation::Count do
  describe "#from_db_result_set" do
    it "returns the expected count value" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "baz", email: "baz@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_1, title: "Post 2")
      Post.create!(author: user_3, title: "Post 3")

      ann = Marten::DB::Query::SQL::Annotation::Count.new(
        field: Post.get_field("id"),
        alias_name: "post_count",
        distinct: false,
        alias_prefix: Post.db_table,
      )

      results = [] of Int64 | Int32 | Int16 | Int8 | Nil

      Marten::DB::Connection.default.open do |db|
        db.query(
          "SELECT COUNT(#{Post.db_table}.#{Post.get_field("id").db_column}) " \
          "FROM #{TestUser.db_table} " \
          "LEFT JOIN #{Post.db_table} " \
          "ON #{TestUser.db_table}.#{TestUser.get_field("id").db_column} = " \
          "#{Post.db_table}.#{Post.get_field("author_id").db_column} " \
          "GROUP BY #{TestUser.db_table}.#{TestUser.get_field("id").db_column} " \
          "ORDER BY #{TestUser.db_table}.#{TestUser.get_field("id").db_column}"
        ) do |result_set|
          result_set.each do
            results << ann.from_db_result_set(result_set)
          end
        end
      end

      results.should eq [2, 0, 1]
    end
  end

  describe "#to_sql" do
    it "returns the expected SQL string" do
      ann = Marten::DB::Query::SQL::Annotation::Count.new(
        field: Post.get_field("id"),
        alias_name: "post_count",
        distinct: false,
        alias_prefix: Post.db_table,
      )

      ann.to_sql.should eq "COUNT(#{Post.db_table}.id) as post_count"
    end

    it "returns the expected SQL string for a distinct count" do
      ann = Marten::DB::Query::SQL::Annotation::Count.new(
        field: Post.get_field("id"),
        alias_name: "post_count",
        distinct: true,
        alias_prefix: Post.db_table,
      )

      ann.to_sql.should eq "COUNT(DISTINCT #{Post.db_table}.id) as post_count"
    end

    it "returns the expected SQL string when with_alias is false" do
      ann = Marten::DB::Query::SQL::Annotation::Count.new(
        field: Post.get_field("id"),
        alias_name: "post_count",
        distinct: false,
        alias_prefix: Post.db_table,
      )

      ann.to_sql(with_alias: false).should eq "COUNT(#{Post.db_table}.id)"
    end
  end
end
