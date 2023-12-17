require "./spec_helper"
require "./row_iterator_spec/app"

describe Marten::DB::Query::SQL::RowIterator do
  with_installed_apps Marten::DB::Query::SQL::RowIteratorSpec::App

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
        id: 1,
        type: Marten::DB::Query::SQL::JoinType::INNER,
        from_model: Post,
        from_common_field: Post.get_field("author_id"),
        reverse_relation: nil,
        to_model: TestUser,
        to_common_field: TestUser.get_field("id"),
        selected: true,
      )

      columns = [] of String

      columns += Post.local_fields.compact_map do |field|
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
    it "yields a row iterator, a common field, and a nil reverse relation for each of the joined relations" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")

      join = Marten::DB::Query::SQL::Join.new(
        id: 1,
        type: Marten::DB::Query::SQL::JoinType::INNER,
        from_model: Post,
        from_common_field: Post.get_field("author_id"),
        reverse_relation: nil,
        to_model: TestUser,
        to_common_field: TestUser.get_field("id"),
        selected: true,
      )

      columns = [] of String
      columns += Post.local_fields.compact_map do |field|
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

            row_iterator.each_joined_relation do |new_row_iterator, common_field, reverse_relation|
              common_field.db_column.should eq "author_id"
              reverse_relation.should be_nil

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

    it "yields the reverse relation associated with the join if one is present" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")

      reverse_relation = Marten::DB::ReverseRelation.new("posts", Post, "author_id")
      join = Marten::DB::Query::SQL::Join.new(
        id: 1,
        type: Marten::DB::Query::SQL::JoinType::INNER,
        from_model: Post,
        from_common_field: Post.get_field("author_id"),
        reverse_relation: reverse_relation,
        to_model: TestUser,
        to_common_field: TestUser.get_field("id"),
        selected: true,
      )

      columns = [] of String
      columns += Post.local_fields.compact_map do |field|
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

            row_iterator.each_joined_relation do |new_row_iterator, common_field, inner_reverse_relation|
              common_field.db_column.should eq "author_id"
              inner_reverse_relation.should eq reverse_relation

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

  describe "#each_parent_column" do
    it "allows to yield a parent model, a result set, and local columns for each of a model's parents" do
      student_1 = Marten::DB::Query::SQL::RowIteratorSpec::AltStudent.create!(
        name: "Student 1",
        email: "student-1@example.com",
        grade: "10",
        alt_grade: "11"
      )
      student_2 = Marten::DB::Query::SQL::RowIteratorSpec::AltStudent.create!(
        name: "Student 2",
        email: "student-2@example.com",
        grade: "12",
        alt_grade: "13"
      )

      parent_model_joins = Marten::DB::Query::SQL::RowIteratorSpec::AltStudent.parent_models
        .map_with_index do |parent_model, i|
          parent_pk_field = if parent_model == Marten::DB::Query::SQL::RowIteratorSpec::Person
                              Marten::DB::Query::SQL::RowIteratorSpec::Person.get_field("id")
                            else
                              parent_model.get_field("person_ptr_id")
                            end

          Marten::DB::Query::SQL::Join.new(
            id: i,
            type: Marten::DB::Query::SQL::JoinType::INNER,
            from_model: Marten::DB::Query::SQL::RowIteratorSpec::AltStudent,
            from_common_field: Marten::DB::Query::SQL::RowIteratorSpec::AltStudent.get_field("student_ptr_id"),
            reverse_relation: nil,
            to_model: parent_model,
            to_common_field: parent_pk_field,
            selected: true,
            table_alias_prefix: "p"
          )
        end

      db_table = Marten::DB::Query::SQL::RowIteratorSpec::AltStudent.db_table

      columns = [] of String
      columns += Marten::DB::Query::SQL::RowIteratorSpec::AltStudent.local_fields.compact_map do |field|
        next unless field.db_column?
        "#{db_table}.#{field.db_column!}"
      end
      columns += parent_model_joins.flat_map(&.columns)

      Marten::DB::Connection.default.open do |db|
        db.query(
          "SELECT #{columns.join(", ")} FROM #{db_table} #{parent_model_joins.join(" ", &.to_sql)}"
        ) do |result_set|
          outer_iteration = 0

          result_set.each do
            row_iterator = Marten::DB::Query::SQL::RowIterator.new(
              Marten::DB::Query::SQL::RowIteratorSpec::AltStudent,
              result_set,
              parent_model_joins
            )

            row_iterator.each_local_column { |rs, _| rs.read(Int8 | ::DB::Any) }

            inner_iteration = 0

            row_iterator.each_parent_column do |parent_model, inner_result_set, column_name|
              if outer_iteration == 0
                if inner_iteration == 0
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Student
                  column_name.should eq "person_ptr_id"
                  inner_result_set.read(Int64).should eq student_1.id
                elsif inner_iteration == 1
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Student
                  column_name.should eq "grade"
                  inner_result_set.read(String).should eq "10"
                elsif inner_iteration == 2
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Person
                  column_name.should eq "id"
                  inner_result_set.read(Int64).should eq student_1.id
                elsif inner_iteration == 3
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Person
                  column_name.should eq "name"
                  inner_result_set.read(String).should eq "Student 1"
                elsif inner_iteration == 4
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Person
                  column_name.should eq "email"
                  inner_result_set.read(String).should eq "student-1@example.com"
                end
              elsif outer_iteration == 1
                if inner_iteration == 0
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Student
                  column_name.should eq "person_ptr_id"
                  inner_result_set.read(Int64).should eq student_2.id
                elsif inner_iteration == 1
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Student
                  column_name.should eq "grade"
                  inner_result_set.read(String).should eq "12"
                elsif inner_iteration == 2
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Person
                  column_name.should eq "id"
                  inner_result_set.read(Int64).should eq student_2.id
                elsif inner_iteration == 3
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Person
                  column_name.should eq "name"
                  inner_result_set.read(String).should eq "Student 2"
                elsif inner_iteration == 4
                  parent_model.should eq Marten::DB::Query::SQL::RowIteratorSpec::Person
                  column_name.should eq "email"
                  inner_result_set.read(String).should eq "student-2@example.com"
                end
              end

              inner_iteration += 1
            end

            outer_iteration += 1
          end
        end
      end
    end
  end
end
