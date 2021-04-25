require "./spec_helper"

describe Marten::DB::Query::SQL::RowIterator do
  describe "#advance" do
    it "allows to skip the local result sets of a specific record" do
      Tag.create!(name: "crystal", is_active: true)
      tag_2 = Tag.create!(name: "coding", is_active: true)

      Marten::DB::Connection.default.open do |db|
        db.query "SELECT * FROM #{Tag.db_table}" do |result_set|
          outer_iteration = 0
          result_set.each do
            row_iterator = Marten::DB::Query::SQL::RowIterator.new(
              Tag,
              result_set,
              Array(Marten::DB::Query::SQL::Join).new
            )

            if outer_iteration == 0
              row_iterator.advance
            else
              inner_iteration = 0
              row_iterator.each_local_column do |rs, column_name|
                outer_iteration.should eq 1

                if inner_iteration == 0
                  column_name.should eq "id"
                  rs.read(Int64).should eq tag_2.id
                elsif inner_iteration == 1
                  column_name.should eq "name"
                  rs.read(String).should eq "coding"
                end

                inner_iteration += 1
              end
            end

            outer_iteration += 1
          end

          outer_iteration.should eq 2
        end
      end
    end

    it "allows to skip the result sets of associated relations when joins are used" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")

      join = Marten::DB::Query::SQL::Join.new(
        1,
        Marten::DB::Query::SQL::JoinType::INNER,
        Post,
        Post.get_field("author_id"),
        TestUser,
        TestUser.get_field("id"),
        true
      )

      columns = [] of String
      columns += Post.fields.compact_map do |field|
        next unless field.db_column?
        "#{Post.db_table}.#{field.db_column!}"
      end
      columns += join.columns

      Marten::DB::Connection.default.open do |db|
        db.query "SELECT #{columns.join(", ")} FROM #{Post.db_table} #{join.to_sql}" do |result_set|
          outer_iteration = 0
          result_set.each do
            row_iterator = Marten::DB::Query::SQL::RowIterator.new(Post, result_set, [join])

            if outer_iteration == 0
              row_iterator.advance
            else
              inner_iteration = 0
              row_iterator.each_local_column do |rs, column_name|
                outer_iteration.should eq 1

                if inner_iteration == 0
                  column_name.should eq "id"
                  rs.read(Int64).should eq post_2.id
                elsif inner_iteration == 1
                  column_name.should eq "author_id"
                  rs.read(Int64).should eq user_2.id
                else
                  rs.read(Int8 | ::DB::Any)
                end

                inner_iteration += 1
              end
            end

            outer_iteration += 1
          end

          outer_iteration.should eq 2
        end
      end
    end
  end

  describe "#each_local_column" do
    it "allows to yield the result set for each of the local columns of a model" do
      tag_1 = Tag.create!(name: "crystal", is_active: true)
      tag_2 = Tag.create!(name: "coding", is_active: true)

      Marten::DB::Connection.default.open do |db|
        db.query "SELECT * FROM #{Tag.db_table}" do |result_set|
          outer_iteration = 0
          result_set.each do
            row_iterator = Marten::DB::Query::SQL::RowIterator.new(
              Tag,
              result_set,
              Array(Marten::DB::Query::SQL::Join).new
            )

            inner_iteration = 0
            row_iterator.each_local_column do |rs, column_name|
              if outer_iteration == 0
                if inner_iteration == 0
                  column_name.should eq "id"
                  rs.read(Int64).should eq tag_1.id
                elsif inner_iteration == 1
                  column_name.should eq "name"
                  rs.read(String).should eq "crystal"
                end
              elsif outer_iteration == 1
                if inner_iteration == 0
                  column_name.should eq "id"
                  rs.read(Int64).should eq tag_2.id
                elsif inner_iteration == 1
                  column_name.should eq "name"
                  rs.read(String).should eq "coding"
                end
              end

              inner_iteration += 1
            end

            outer_iteration += 1
          end

          outer_iteration.should eq 2
        end
      end
    end
  end

  describe "#each_joined_relation" do
    it "allows to a row iterator and a common field for each of the joined relations" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")

      join = Marten::DB::Query::SQL::Join.new(
        1,
        Marten::DB::Query::SQL::JoinType::INNER,
        Post,
        Post.get_field("author_id"),
        TestUser,
        TestUser.get_field("id"),
        true
      )

      columns = [] of String
      columns += Post.fields.compact_map do |field|
        next unless field.db_column?
        "#{Post.db_table}.#{field.db_column!}"
      end
      columns += join.columns

      Marten::DB::Connection.default.open do |db|
        db.query "SELECT #{columns.join(", ")} FROM #{Post.db_table} #{join.to_sql}" do |result_set|
          outer_iteration = 0
          result_set.each do
            row_iterator = Marten::DB::Query::SQL::RowIterator.new(Post, result_set, [join])

            row_iterator.each_local_column { |rs, _| rs.read(Int8 | ::DB::Any) }

            inner_iteration = 0

            row_iterator.each_joined_relation do |new_row_iterator, common_field|
              common_field.db_column.should eq "author_id"

              relation_iteration = 0
              new_row_iterator.each_local_column do |rs, column_name|
                if outer_iteration == 0 && inner_iteration == 0 && relation_iteration == 0
                  column_name.should eq "id"
                  rs.read(Int64).should eq user_1.id
                elsif outer_iteration == 0 && inner_iteration == 0 && relation_iteration == 1
                  column_name.should eq "username"
                  rs.read(String).should eq user_1.username
                elsif outer_iteration == 1 && inner_iteration == 0 && relation_iteration == 0
                  column_name.should eq "id"
                  rs.read(Int64).should eq user_2.id
                elsif outer_iteration == 1 && inner_iteration == 0 && relation_iteration == 1
                  column_name.should eq "username"
                  rs.read(String).should eq user_2.username
                else
                  rs.read(Int8 | ::DB::Any)
                end

                relation_iteration += 1
              end

              inner_iteration += 1
            end

            outer_iteration += 1
          end

          outer_iteration.should eq 2
        end
      end
    end
  end
end
