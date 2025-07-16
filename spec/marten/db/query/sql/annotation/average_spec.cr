require "./spec_helper"

describe Marten::DB::Query::SQL::Annotation::Average do
  describe "#from_db_result_set" do
    it "returns the expected average values" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "baz", email: "baz@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1", score: 10.0)
      Post.create!(author: user_1, title: "Post 2", score: 20.0)
      Post.create!(author: user_3, title: "Post 3", score: 30.0)

      ann = Marten::DB::Query::SQL::Annotation::Average.new(
        field: Post.get_field("score"),
        alias_name: "score_avg",
        distinct: false,
        alias_prefix: Post.db_table,
      )

      results = [] of Float64 | Float32 | Nil

      Marten::DB::Connection.default.open do |db|
        db.query(
          "SELECT AVG(#{Post.get_field("score").db_column}) " \
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

      results.should eq [15.0, nil, 30.0]
    end
  end

  describe "#to_sql" do
    it "returns the expected SQL string" do
      ann = Marten::DB::Query::SQL::Annotation::Average.new(
        field: Post.get_field("score"),
        alias_name: "score_avg",
        distinct: false,
        alias_prefix: Post.db_table,
      )

      ann.to_sql.should eq "AVG(#{Post.db_table}.score) as score_avg"
    end

    it "returns the expected SQL string for a distinct average" do
      ann = Marten::DB::Query::SQL::Annotation::Average.new(
        field: Post.get_field("score"),
        alias_name: "score_avg",
        distinct: true,
        alias_prefix: Post.db_table,
      )

      ann.to_sql.should eq "AVG(DISTINCT #{Post.db_table}.score) as score_avg"
    end

    it "returns the expected SQL string when with_alias is false" do
      ann = Marten::DB::Query::SQL::Annotation::Average.new(
        field: Post.get_field("score"),
        alias_name: "score_avg",
        distinct: false,
        alias_prefix: Post.db_table,
      )

      ann.to_sql(with_alias: false).should eq "AVG(#{Post.db_table}.score)"
    end
  end
end
