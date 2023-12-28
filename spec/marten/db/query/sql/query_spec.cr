require "./spec_helper"
require "./query_spec/app"

describe Marten::DB::Query::SQL::Query do
  with_installed_apps Marten::DB::Query::SQL::QuerySpec::App

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

    it "is able to process query nodes with filters on many-to-many relations" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_1.tags.add(tag_1, tag_2)
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")
      user_2.tags.add(tag_2, tag_3)

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.add_query_node(Marten::DB::Query::Node.new(tags__name__startswith: "r"))
      query.count.should eq 1
      query.execute.to_a.should eq [user_1]
    end

    it "is able to process query nodes with filters on many-to-many relations plus additional relations" do
      address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
      address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")
      address_3 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Other Street")

      person_1 = Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Person 1",
        email: "person-1@example.com",
        address: address_1,
      )
      person_2 = Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Person 2",
        email: "person-2@example.com",
        address: address_2,
      )
      person_3 = Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Person 3",
        email: "person-3@example.com",
        address: address_3,
      )

      book_1 = Marten::DB::Query::SQL::QuerySpec::Book.create!(title: "Book 1")
      book_1.authors.add(person_1, person_2)
      book_2 = Marten::DB::Query::SQL::QuerySpec::Book.create!(title: "Book 2")
      book_2.authors.add(person_2)
      book_3 = Marten::DB::Query::SQL::QuerySpec::Book.create!(title: "Book 3")
      book_3.authors.add(person_3)

      query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Book).new
      query.add_query_node(Marten::DB::Query::Node.new(authors__address__street__istartswith: "main"))
      query.count.should eq 2
      query.execute.to_set.should eq [book_1, book_2].to_set
    end

    it "is able to process query nodes with filters on reverse many-to-many relations" do
      address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
      address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")
      address_3 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Other Street")

      person_1 = Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Person 1",
        email: "person-1@example.com",
        address: address_1,
      )
      person_2 = Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Person 2",
        email: "person-2@example.com",
        address: address_2,
      )
      person_3 = Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Person 3",
        email: "person-3@example.com",
        address: address_3,
      )

      book_1 = Marten::DB::Query::SQL::QuerySpec::Book.create!(title: "Book 1")
      book_1.authors.add(person_1)
      book_2 = Marten::DB::Query::SQL::QuerySpec::Book.create!(title: "Book 2")
      book_2.authors.add(person_2)
      book_3 = Marten::DB::Query::SQL::QuerySpec::Book.create!(title: "Book 3-1")
      book_3.authors.add(person_3)

      query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Person).new
      query.add_query_node(Marten::DB::Query::Node.new(books__title__endswith: "1"))
      query.count.should eq 2
      query.execute.to_set.should eq [person_1, person_3].to_set
    end

    it "adds a root predicate to prevent inconsistencies based on the order of negated and non-negated predicates" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.add_query_node(Marten::DB::Query::Node.new(name__startswith: :c))
      query_1.add_query_node(-Marten::DB::Query::Node.new(pk: tag_3.pk))
      query_1.count.should eq 1
      query_1.execute.should eq [tag_2]

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.add_query_node(-Marten::DB::Query::Node.new(pk: tag_3.pk))
      query_2.add_query_node(Marten::DB::Query::Node.new(name__startswith: :c))
      query_2.count.should eq 1
      query_2.execute.should eq [tag_2]
    end

    it "raises if a query node targeting an unknown field is added" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Unable to resolve 'unknown' as a field. Valid choices are: id, name, is_active."
      ) do
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

    context "with multi table inheritance" do
      it "can filter on local attributes seamlessly" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11"
        )
        Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address,
          grade: "12"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query.add_query_node(Marten::DB::Query::Node.new(grade: "11"))
        query.count.should eq 1
        query.execute.should eq [student_2]
      end

      it "can filter on local attributes seamlessly with multiple levels of inheritance" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "20"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11",
          alt_grade: "21"
        )
        Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address,
          grade: "12",
          alt_grade: "22"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query.add_query_node(Marten::DB::Query::Node.new(alt_grade: "21"))
        query.count.should eq 1
        query.execute.should eq [student_2]
      end

      it "can filter on parent attributes seamlessly" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student_1 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11"
        )
        Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address,
          grade: "12"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query.add_query_node(Marten::DB::Query::Node.new(name__istartswith: "student"))
        query.count.should eq 2
        query.execute.should eq [student_1, student_2]
      end

      it "can filter on parent attributes seamlessly with multiple levels of inheritance" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student_1 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "20"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11",
          alt_grade: "21"
        )
        Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address,
          grade: "12",
          alt_grade: "22"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query.add_query_node(Marten::DB::Query::Node.new(name__istartswith: "student"))
        query.count.should eq 2
        query.execute.should eq [student_1, student_2]

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query.add_query_node(Marten::DB::Query::Node.new(grade: "11"))
        query.count.should eq 1
        query.execute.should eq [student_2]
      end

      it "can filter on local relation attributes seamlessly" do
        address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")
        alt_address_1 = Marten::DB::Query::SQL::QuerySpec::AltAddress.create!(street: "Street 1")
        alt_address_2 = Marten::DB::Query::SQL::QuerySpec::AltAddress.create!(street: "Main Street")
        Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address_1,
          grade: "10",
          alt_grade: "20",
          alt_address: alt_address_1
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address_2,
          grade: "11",
          alt_grade: "21",
          alt_address: alt_address_2
        )
        Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address_1,
          grade: "12",
          alt_address: alt_address_1,
          alt_grade: "22"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query.add_query_node(Marten::DB::Query::Node.new(alt_address__street__istartswith: "main"))
        query.count.should eq 1
        query.execute.should eq [student_2]
      end

      it "can filter on parent relation attributes seamlessly" do
        address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")
        Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address_1,
          grade: "10"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address_2,
          grade: "11"
        )
        Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address_1,
          grade: "12"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query.add_query_node(Marten::DB::Query::Node.new(address__street__istartswith: "main"))
        query.count.should eq 1
        query.execute.should eq [student_2]
      end

      it "can filter on parent relation attributes seamlessly with multiple levels of inheritance" do
        address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")
        Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address_1,
          grade: "10",
          alt_grade: "20"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address_2,
          grade: "11",
          alt_grade: "21"
        )
        Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address_1,
          grade: "12",
          alt_grade: "22"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query.add_query_node(Marten::DB::Query::Node.new(address__street__istartswith: "main"))
        query.count.should eq 1
        query.execute.should eq [student_2]
      end

      it "can filter on local reverse relation attributes seamlessly" do
        address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")

        student_1 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address_1,
          grade: "10",
          alt_grade: "20"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address_2,
          grade: "11",
          alt_grade: "21"
        )
        student_3 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address_1,
          grade: "12",
          alt_grade: "22"
        )

        Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(title: "Top things", author: student_1)
        Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(title: "10 reasons to code", author: student_2)
        Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(title: "Test article", author: student_3)

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query.add_query_node(Marten::DB::Query::Node.new(alt_articles__title__icontains: "reasons"))
        query.count.should eq 1
        query.execute.should eq [student_2]
      end

      it "can filter on parent reverse relation attributes seamlessly" do
        address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")

        student_1 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address_1,
          grade: "10"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address_2,
          grade: "11"
        )
        student_3 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address_1,
          grade: "12"
        )

        Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "Top things", author: student_1)
        Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "10 reasons to code", author: student_2)
        Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "Test article", author: student_3)

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query.add_query_node(Marten::DB::Query::Node.new(articles__title__icontains: "reasons"))
        query.count.should eq 1
        query.execute.should eq [student_2]
      end

      it "can filter on parent reverse relation attributes seamlessly with multiple levels of inheritance" do
        address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")

        student_1 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address_1,
          grade: "10",
          alt_grade: "20"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address_2,
          grade: "11",
          alt_grade: "21"
        )
        student_3 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address_1,
          grade: "12",
          alt_grade: "22"
        )

        Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "Top things", author: student_1)
        Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "10 reasons to code", author: student_2)
        Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "Test article", author: student_3)

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query.add_query_node(Marten::DB::Query::Node.new(articles__title__icontains: "reasons"))
        query.count.should eq 1
        query.execute.should eq [student_2]
      end

      it "can filter on local attributes of relations that target models using multi table inheritance" do
        address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")

        student_1 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address_1,
          grade: "10",
          alt_grade: "20"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address_2,
          grade: "11",
          alt_grade: "21"
        )
        student_3 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address_1,
          grade: "12",
          alt_grade: "22"
        )

        Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(title: "Top things", author: student_1)
        article_2 = Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(
          title: "10 reasons to code",
          author: student_2
        )
        Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(title: "Test article", author: student_3)

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltArticle).new
        query.add_query_node(Marten::DB::Query::Node.new(author__alt_grade: "21"))
        query.count.should eq 1
        query.execute.should eq [article_2]
      end

      it "can filter on parent attributes of relations that target models using multi table inheritance" do
        address_1 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        address_2 = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Main Street")

        student_1 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address_1,
          grade: "10",
          alt_grade: "20"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address_2,
          grade: "11",
          alt_grade: "21"
        )
        student_3 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Other Student",
          email: "other-student@example.com",
          address: address_1,
          grade: "12",
          alt_grade: "22"
        )

        Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(title: "Top things", author: student_1)
        article_2 = Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(
          title: "10 reasons to code",
          author: student_2
        )
        Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(title: "Test article", author: student_3)

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltArticle).new
        query.add_query_node(Marten::DB::Query::Node.new(author__name: "Student 2"))
        query.count.should eq 1
        query.execute.should eq [article_2]
      end
    end
  end

  describe "#add_selected_join" do
    it "allows to specify a relation to join" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_selected_join("author")

      results = query.execute

      results[0].__query_spec_author.should eq user_1
      results[1].__query_spec_author.should eq user_2
    end

    it "allows to specify a one-to-one reverse relation to join" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_profile_1 = TestUserProfile.create!(user: user_1)
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.add_selected_join("profile")

      results = query.execute

      results[0].should eq user_1
      results[0].__query_spec_profile.should eq user_profile_1

      results[1].should eq user_2
      results[1].__query_spec_profile.should be_nil
    end

    it "raises if the passed field is not a relation" do
      query = Marten::DB::Query::SQL::Query(Post).new
      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Unable to resolve 'title' as a relation field. Valid choices are:"
      ) do
        query.add_selected_join("title")
      end
    end

    it "raises if the passed field is not a single record reverse relation" do
      query = Marten::DB::Query::SQL::Query(TestUser).new
      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Unable to resolve 'posts' as a relation field. Valid choices are:"
      ) do
        query.add_selected_join("posts")
      end
    end

    context "with multi table inheritance" do
      it "allows to specify a relation that targets a top-level parent model" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )
        Marten::DB::Query::SQL::QuerySpec::Article.create!(author: student, title: "Test article")

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Article).new
        query.add_selected_join("author")

        results = query.execute

        results[0].__query_spec_author.should eq student.person_ptr
      end

      it "allows to specify a relation that targets a child model" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )
        Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(author: student, title: "Test article")

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltArticle).new
        query.add_selected_join("author")

        results = query.execute

        results[0].__query_spec_author.should eq student
      end

      it "allows to specify a relation that goes through a child model" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )
        Marten::DB::Query::SQL::QuerySpec::AltArticle.create!(author: student, title: "Test article")

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltArticle).new
        query.add_selected_join("author__address")

        results = query.execute

        results[0].__query_spec_author.should eq student
        results[0].__query_spec_author.not_nil!.__query_spec_address.should eq address
      end

      it "allows to specify direct one-to-one reverse relations" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 2")
        student = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        Marten::DB::Query::SQL::QuerySpec::PersonProfile.create!(person: student)
        student_profile = Marten::DB::Query::SQL::QuerySpec::StudentProfile.create!(student: student)

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query.add_selected_join("student_profile")

        results = query.execute

        results[0].should eq student
        results[0].__query_spec_student_profile.should eq student_profile
      end

      it "allows to specify inherited one-to-one reverse relations" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 2")
        student = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        person_profile = Marten::DB::Query::SQL::QuerySpec::PersonProfile.create!(person: student)
        Marten::DB::Query::SQL::QuerySpec::StudentProfile.create!(student: student)

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query.add_selected_join("person_profile")

        results = query.execute

        results[0].should eq student
        results[0].__query_spec_person_profile.should eq person_profile
      end

      it "allows to specify both direct and inherited one-to-one reverse relations at the same time" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 2")
        student = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        person_profile = Marten::DB::Query::SQL::QuerySpec::PersonProfile.create!(person: student)
        student_profile = Marten::DB::Query::SQL::QuerySpec::StudentProfile.create!(student: student)

        query_1 = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query_1.add_selected_join("person_profile")
        query_1.add_selected_join("student_profile")
        results_1 = query_1.execute

        results_1[0].should eq student
        results_1[0].__query_spec_person_profile.should eq person_profile
        results_1[0].__query_spec_student_profile.should eq student_profile

        query_2 = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query_2.add_selected_join("student_profile")
        query_2.add_selected_join("person_profile")
        results_2 = query_2.execute

        results_2[0].should eq student
        results_2[0].__query_spec_person_profile.should eq person_profile
        results_2[0].__query_spec_student_profile.should eq student_profile
      end

      it "allows to specify a related record that inherits from other records" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 2")
        student = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        student_profile = Marten::DB::Query::SQL::QuerySpec::StudentProfile.create!(student: student)

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::StudentProfile).new
        query.add_selected_join("student")

        results = query.execute

        results[0].should eq student_profile
        results[0].__query_spec_student.should eq student
      end
    end
  end

  describe "#clone" do
    it "results in a new object" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.clone.object_id.should_not eq query.object_id
    end

    it "properly clones a query by respecting the default ordering" do
      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.default_ordering = true
      query_1.clone.default_ordering.should be_true

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.default_ordering = false
      query_2.clone.default_ordering.should be_false
    end

    it "properly clones a query by respecting joins" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_selected_join("author")

      results = query.clone.execute

      results[0].__query_spec_author.should eq user_1
      results[1].__query_spec_author.should eq user_2
    end

    it "properly clones a query by respecting limits and offsets" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("id")
      query.slice(1, 2)
      query.clone.execute.should eq [tag_2, tag_3]
    end

    it "properly clones a query by respecting order clauses" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("name")
      query.clone.execute.should eq [tag_3, tag_2, tag_1]
    end

    it "properly clones a query by respecting predicates" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.add_query_node(Marten::DB::Query::Node.new(name__startswith: "r"))
      query.clone.execute.should eq [tag_1]
    end

    it "properly clones a query by respecting the active DB alias" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.using(:other).create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.using = "other"
      query.clone.count.should eq 1
    end
  end

  describe "#connection" do
    it "returns the model connection by default" do
      Marten::DB::Query::SQL::Query(Tag).new.connection.should eq Tag.connection
    end

    it "returns the specified connection if applicable" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.using = "other"
      query.connection.should eq Marten::DB::Connection.get("other")
    end
  end

  describe "#count" do
    it "returns the expected number of results for an unfiltered query" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::SQL::Query(Tag).new.count.should eq 3
    end

    it "returns the expected number of results for an unfiltered query with specific column defined" do
      address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")

      student = Marten::DB::Query::SQL::QuerySpec::Student.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
        grade: "10"
      )

      Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "Top things", author: student)
      Marten::DB::Query::SQL::QuerySpec::Article.create!(
        title: "Top things 2",
        subtitle: "Rise of the top things",
        author: student
      )
      Marten::DB::Query::SQL::QuerySpec::Article.create!(
        title: "Top things 3",
        subtitle: "Top things awakening",
        author: student
      )

      Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Article).new.count("subtitle").should eq 2
    end

    it "returns the expected number of results when counting on a specific column located on a direct relationship" do
      address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")

      student_1 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
        grade: "10"
      )
      student_2 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
        name: "Student 1",
        surname: "Student 1",
        email: "student-1@example.com",
        address: address,
        grade: "10",
      )

      Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "Top things", author: student_1)
      Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "Top things", author: student_2)
      Marten::DB::Query::SQL::QuerySpec::Article.create!(title: "Top things", author: student_2)

      Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Article).new.count("author__surname").should eq 2
    end

    it "returns the expected number of results when counting on a specific relationship column" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")
      Post.create!(author: user_1, updated_by: user_2, title: "Post 3")

      Marten::DB::Query::SQL::Query(Post).new.count("updated_by").should eq 1
      Marten::DB::Query::SQL::Query(Post).new.count("updated_by_id").should eq 1
    end

    it "returns the expected number of results when counting on a field going through a reverse relation" do
      address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")

      person_1 = Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
      )
      Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
      )
      Marten::DB::Query::SQL::QuerySpec::PersonProfile.create!(person: person_1, bio: "Bio 1")

      query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Person).new
      query.count("person_profile__bio").should eq 1
    end

    it "returns the expected number of results when counting on a specific reverse relation" do
      address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")

      person_1 = Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
      )
      Marten::DB::Query::SQL::QuerySpec::Person.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
      )
      Marten::DB::Query::SQL::QuerySpec::PersonProfile.create!(person: person_1)

      Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Person).new.count("person_profile").should eq 1
    end

    it "raises if non existing field is counted" do
      expect_raises(
        Marten::DB::Errors::InvalidField,
        "Unable to resolve 'not_existing' as a field. Valid choices are: author_id, id, title, subtitle."
      ) do
        Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Article).new.count("not_existing")
      end
    end

    it "raises if the specified field is a many-to-many field" do
      expect_raises(Marten::DB::Errors::InvalidField, "Unable to resolve 'tags' as a field.") do
        Marten::DB::Query::SQL::Query(TestUser).new.count("tags")
      end
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

  describe "#execute" do
    it "returns the expected results for an unfiltered query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::SQL::Query(Tag).new.execute.to_set.should eq [tag_1, tag_2, tag_3].to_set
    end

    it "returns the expected results for a filtered query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.add_query_node(Marten::DB::Query::Node.new(name__startswith: :c))
      query_1.execute.to_set.should eq [tag_2, tag_3].to_set

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.add_query_node(Marten::DB::Query::Node.new(name__startswith: "r"))
      query_2.execute.should eq [tag_1]

      query_3 = Marten::DB::Query::SQL::Query(Tag).new
      query_3.add_query_node(Marten::DB::Query::Node.new(name__startswith: "x"))
      query_3.execute.should be_empty
    end

    it "returns the expected results for a filtered query involving joins" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_1, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(author__username__startswith: "f"))
      query.execute.to_set.should eq [post_1, post_3].to_set
    end

    it "returns the expected results for a sliced query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.order("id")
      query_1.slice(1)
      query_1.execute.should eq [tag_2, tag_3]

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.order("id")
      query_2.slice(1, 1)
      query_2.execute.should eq [tag_2]

      query_3 = Marten::DB::Query::SQL::Query(Tag).new
      query_3.order("id")
      query_3.slice(1, 2)
      query_3.execute.should eq [tag_2, tag_3]

      query_4 = Marten::DB::Query::SQL::Query(Tag).new
      query_4.order("id")
      query_4.slice(0)
      query_4.execute.should eq [tag_1, tag_2, tag_3]
    end

    it "makes use of the specified DB connection" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.using(:other).create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.using = "other"
      query.execute.should eq [tag_3]
    end

    it "makes use of the specified order" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.order("id")
      query_1.execute.should eq [tag_1, tag_2, tag_3]

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.order("name")
      query_2.execute.should eq [tag_3, tag_2, tag_1]

      query_3 = Marten::DB::Query::SQL::Query(Tag).new
      query_3.order("-name")
      query_3.execute.should eq [tag_1, tag_2, tag_3]
    end
  end

  describe "#exists?" do
    it "returns the expected booleans for an unfiltered query" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::SQL::Query(Tag).new.exists?.should be_true
      Marten::DB::Query::SQL::Query(Post).new.exists?.should be_false
    end

    it "returns the expected booleans for a filtered query" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.add_query_node(Marten::DB::Query::Node.new(name__startswith: :c))
      query_1.exists?.should be_true

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.add_query_node(Marten::DB::Query::Node.new(name__startswith: "r"))
      query_2.exists?.should be_true

      query_3 = Marten::DB::Query::SQL::Query(Tag).new
      query_3.add_query_node(Marten::DB::Query::Node.new(name__startswith: "x"))
      query_3.exists?.should be_false
    end

    it "returns the expected booleans for a filtered query involving joins" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")
      Post.create!(author: user_1, title: "Post 3")

      query_1 = Marten::DB::Query::SQL::Query(Post).new
      query_1.add_query_node(Marten::DB::Query::Node.new(author__username__startswith: "f"))
      query_1.exists?.should be_true

      query_2 = Marten::DB::Query::SQL::Query(Post).new
      query_2.add_query_node(Marten::DB::Query::Node.new(author__username__startswith: "a"))
      query_2.exists?.should be_false
    end

    it "returns the expected booleans for a sliced query" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.order("id")
      query_1.slice(1)
      query_1.exists?.should be_true

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.order("id")
      query_2.slice(1, 1)
      query_2.exists?.should be_true

      query_3 = Marten::DB::Query::SQL::Query(Tag).new
      query_3.order("id")
      query_3.slice(1, 2)
      query_3.exists?.should be_true

      query_4 = Marten::DB::Query::SQL::Query(Tag).new
      query_4.order("id")
      query_4.slice(0)
      query_4.exists?.should be_true

      query_5 = Marten::DB::Query::SQL::Query(Tag).new
      query_5.order("id")
      query_5.slice(5, 6)
      query_5.exists?.should be_false
    end

    it "makes use of the specified DB connection" do
      Tag.using(:other).create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.using = "other"
      query_1.exists?.should be_true

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.exists?.should be_false
    end
  end

  describe "#joins?" do
    it "returns true if joins are used" do
      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(author__username__startswith: "f"))
      query.joins?.should be_true
    end

    it "returns false if no joins are used" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.add_query_node(Marten::DB::Query::Node.new(name__startswith: "t"))
      query.joins?.should be_false
    end
  end

  describe "#order" do
    it "can configure a query to be ordered by a single field" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("name")
      query.execute.should eq [tag_3, tag_2, tag_1]
    end

    it "can configure a query to be ordered by a single field in reverse order" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("-name")
      query.execute.should eq [tag_1, tag_2, tag_3]
    end

    it "can configure a query to be ordered by multiple fields" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Foo", last_name: "Bar")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Bob", last_name: "Ka")
      user_4 = TestUser.create!(username: "u4", email: "u4@example.com", first_name: "John", last_name: "Arg")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.order("first_name", "last_name")
      query.execute.should eq [user_3, user_2, user_4, user_1]
    end

    it "can configure a query to be ordered by multiple fields in various orders" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Foo", last_name: "Bar")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Bob", last_name: "Ka")
      user_4 = TestUser.create!(username: "u4", email: "u4@example.com", first_name: "John", last_name: "Arg")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.order("first_name", "-last_name")
      query.execute.should eq [user_3, user_2, user_1, user_4]
    end

    it "properly makes use of joins" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Bob", last_name: "Ka")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Foo", last_name: "Bar")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_3, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.order("author__first_name")
      query.execute.should eq [post_2, post_3, post_1]
    end

    it "can order from an array of strings" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Foo", last_name: "Bar")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Bob", last_name: "Ka")
      user_4 = TestUser.create!(username: "u4", email: "u4@example.com", first_name: "John", last_name: "Arg")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.order(["first_name", "last_name"])
      query.execute.should eq [user_3, user_2, user_4, user_1]
    end

    it "can order from an array of symbols" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Foo", last_name: "Bar")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Bob", last_name: "Ka")
      user_4 = TestUser.create!(username: "u4", email: "u4@example.com", first_name: "John", last_name: "Arg")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.order([:first_name, :last_name])
      query.execute.should eq [user_3, user_2, user_4, user_1]
    end

    it "can configure a query to be ordered by a field going through a direct relationship field" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Bob", last_name: "Ka")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Foo", last_name: "Bar")

      post_1 = Post.create!(author: user_2, title: "Post 1")
      post_2 = Post.create!(author: user_1, title: "Post 2")
      post_3 = Post.create!(author: user_3, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.order("author__username")
      query.execute.should eq [post_2, post_1, post_3]
    end

    it "can configure a query to be ordered by a direct relationship field" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Bob", last_name: "Ka")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Foo", last_name: "Bar")

      post_1 = Post.create!(author: user_2, title: "Post 1")
      post_2 = Post.create!(author: user_1, title: "Post 2")
      post_3 = Post.create!(author: user_3, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.order("author")
      query.execute.should eq [post_2, post_1, post_3]
    end

    it "can configure a query to be ordered by a field going through a reverse relation" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Bob", last_name: "Ka")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Foo", last_name: "Bar")

      TestUserProfile.create!(user: user_1, bio: "Bio B")
      TestUserProfile.create!(user: user_2, bio: "Bio A")
      TestUserProfile.create!(user: user_3, bio: "Bio C")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.order("profile__bio")
      query.execute.should eq [user_2, user_1, user_3]
    end

    it "can configure a query to be ordered by a reverse relation" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Bob", last_name: "Ka")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Foo", last_name: "Bar")

      TestUserProfile.create!(user: user_1, bio: "Bio B")
      TestUserProfile.create!(user: user_2, bio: "Bio A")
      TestUserProfile.create!(user: user_3, bio: "Bio C")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.order("profile")
      query.execute.should eq [user_1, user_2, user_3]
    end

    it "raises if the specified field is a many-to-many field" do
      expect_raises(Marten::DB::Errors::InvalidField, "Unable to resolve 'tags' as a field.") do
        Marten::DB::Query::SQL::Query(TestUser).new.order(["tags"])
      end
    end
  end

  describe "#ordered?" do
    it "returns true if the query is ordered" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("name")
      query.ordered?.should be_true
    end

    it "returns false if the query is not ordered" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.ordered?.should be_false
    end
  end

  describe "#raw_delete" do
    it "performs a raw delete and returns the number of deleted rows" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.raw_delete.should eq 3
      query.exists?.should be_false
    end

    it "returns 0 if no rows are currently targetted by the query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.add_query_node(Marten::DB::Query::Node.new(name__startswith: "z"))
      query.raw_delete.should eq 0

      Marten::DB::Query::SQL::Query(Tag).new.execute.to_set.should eq(Set{tag_1, tag_2, tag_3})
    end

    it "makes use of the specified DB connection" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      Tag.using(:other).create!(name: "other", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.using = "other"
      query_1.raw_delete.should eq 1
      query_1.exists?.should be_false

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.execute.to_set.should eq(Set{tag_1, tag_2, tag_3})
    end

    it "properly makes use of filters involving joins if applicable" do
      user_1 = TestUser.create!(username: "u1", email: "u1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "u2", email: "u2@example.com", first_name: "Bob", last_name: "Ka")
      user_3 = TestUser.create!(username: "u3", email: "u3@example.com", first_name: "Foo", last_name: "Bar")

      Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_3, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(author__first_name: "John"))
      query.raw_delete.should eq 1

      Marten::DB::Query::SQL::Query(Post).new.execute.to_set.should eq(Set{post_2, post_3})
    end
  end

  describe "#pluck" do
    it "allows extracting a single field values" do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.pluck(["username"]).should eq [["jd1"], ["jd2"], ["jd3"]]
    end

    it "is consistent with the current filters" do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.add_query_node(Marten::DB::Query::Node.new(first_name: "John"))
      query.pluck(["username"]).should eq [["jd1"], ["jd2"]]
    end

    it "allows extracting multiple fields values" do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.pluck(["first_name", "last_name"]).should eq [["John", "Doe"], ["John", "Doe"], ["Bob", "Doe"]]
    end

    it "allows extracting field values by following joins" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1", published: true)
      Post.create!(author: user_1, title: "Post 2", published: true)
      Post.create!(author: user_2, title: "Post 3", published: true)
      Post.create!(author: user_1, title: "Post 4", published: false)
      Post.create!(author: user_3, title: "Post 5", published: false)

      query = Marten::DB::Query::SQL::Query(Post).new
      query.pluck(["title", "author__first_name"]).to_set.should eq(
        [["Post 1", "John"], ["Post 2", "John"], ["Post 3", "John"], ["Post 4", "John"], ["Post 5", "Bob"]].to_set
      )
    end

    it "allows extracting field values by following reverse relations" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

      TestUserProfile.create!(user: user_1, bio: "Bio 1")
      TestUserProfile.create!(user: user_2, bio: "Bio 2")
      TestUserProfile.create!(user: user_3, bio: "Bio 3")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.pluck(["username", "profile__bio"]).to_set.should eq(
        [["jd1", "Bio 1"], ["jd2", "Bio 2"], ["jd3", "Bio 3"]].to_set
      )
    end

    it "allows extracting reverse relations directly" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

      profile_1 = TestUserProfile.create!(user: user_1, bio: "Bio 1")
      profile_2 = TestUserProfile.create!(user: user_2, bio: "Bio 2")
      profile_3 = TestUserProfile.create!(user: user_3, bio: "Bio 3")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.pluck(["username", "profile"]).to_set.should eq(
        [["jd1", profile_1.id], ["jd2", profile_2.id], ["jd3", profile_3.id]].to_set
      )
    end
  end

  describe "#setup_distinct_clause" do
    it "allows to configure a global distinct clause for the query" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1", published: true)
      Post.create!(author: user_1, title: "Post 2", published: true)
      Post.create!(author: user_2, title: "Post 3", published: true)
      Post.create!(author: user_1, title: "Post 4", published: false)

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.setup_distinct_clause

      query.count.should eq 2
      query.execute.to_set.should eq [user_1, user_2].to_set
    end

    for_postgresql do
      it "allows to configure a distinct clause based on a specific field" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        query = Marten::DB::Query::SQL::Query(TestUser).new
        query.setup_distinct_clause(["first_name"])

        query.count.should eq 2
        query.execute.to_set.should eq [user_1, user_3].to_set
      end

      it "allows to configure a distinct clause based on multiple fields" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        query = Marten::DB::Query::SQL::Query(TestUser).new
        query.setup_distinct_clause(["first_name", "last_name"])

        query.count.should eq 2
        query.execute.to_set.should eq [user_1, user_3].to_set
      end

      it "allows to configure a distinct clause based on a specific field by following joins" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        post_1 = Post.create!(author: user_1, title: "Post 1", published: true)
        Post.create!(author: user_1, title: "Post 2", published: true)
        Post.create!(author: user_2, title: "Post 3", published: true)
        Post.create!(author: user_1, title: "Post 4", published: false)
        post_5 = Post.create!(author: user_3, title: "Post 4", published: false)

        query = Marten::DB::Query::SQL::Query(Post).new
        query.setup_distinct_clause(["author__first_name"])

        query.count.should eq 2
        query.execute.to_set.should eq [post_1, post_5].to_set
      end

      it "allows to configure a distinct clause based on a specific field by following reverse relations" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUserProfile.create!(user: user_1, bio: "Bio 1")
        TestUserProfile.create!(user: user_2, bio: "Bio 2")
        TestUserProfile.create!(user: user_3, bio: "Bio 1")

        query = Marten::DB::Query::SQL::Query(TestUser).new
        query.setup_distinct_clause(["profile__bio"])

        query.count.should eq 2
        query.execute.to_set.should eq [user_1, user_2].to_set
      end

      it "allows to configure a distinct clause based on a specific reverse relation" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUserProfile.create!(user: user_1, bio: "Bio 1")
        TestUserProfile.create!(user: user_2, bio: "Bio 2")
        TestUserProfile.create!(user: user_3, bio: "Bio 1")

        query = Marten::DB::Query::SQL::Query(TestUser).new
        query.setup_distinct_clause(["profile"])

        query.count.should eq 3
      end

      it "raises if the specified field is a many-to-many field" do
        expect_raises(Marten::DB::Errors::InvalidField, "Unable to resolve 'tags' as a field.") do
          Marten::DB::Query::SQL::Query(TestUser).new.setup_distinct_clause(["tags"])
        end
      end
    end
  end

  describe "#slice" do
    it "allows to configure an offset on a non-sliced query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.order("name")
      query_1.slice(1)
      query_1.count.should eq 2
      query_1.execute.should eq [tag_2, tag_1]

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.order("name")
      query_2.slice(2)
      query_2.count.should eq 1
      query_2.execute.should eq [tag_1]
    end

    it "allows to configure an offset and a limit on a non-sliced query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.order("name")
      query_1.slice(1, 1)
      query_1.count.should eq 1
      query_1.execute.should eq [tag_2]

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.order("name")
      query_2.slice(1, 2)
      query_2.count.should eq 2
      query_2.execute.should eq [tag_2, tag_1]

      query_3 = Marten::DB::Query::SQL::Query(Tag).new
      query_3.order("name")
      query_3.slice(2, 1)
      query_3.count.should eq 1
      query_3.execute.should eq [tag_1]
    end

    it "can apply a new offset to an already sliced query if it is within the current limits" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("name")
      query.slice(1, 2)
      query.slice(1)
      query.execute.should eq [tag_1]
    end

    it "does not return results that are outside of the current bounds when a new offset without limit is used" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "xyz", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("name")
      query.slice(1, 2)
      query.slice(1)
      query.execute.should eq [tag_1]
    end

    it "does not return results that are outside of the current bounds when a new offset with limit is used" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "xyz", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("name")
      query.slice(1, 2)
      query.slice(1, 6)
      query.execute.should eq [tag_1]
    end

    it "returns an empty set if the new offset falls outside of the current limits" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("name")
      query.slice(1, 2)
      query.slice(4)
      query.execute.should be_empty
    end
  end

  describe "#sliced?" do
    it "returns true if the query is sliced using only an offset" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.slice(4)
      query.sliced?.should be_true
    end

    it "returns true if the query is sliced using only an offset and a limit" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.slice(4, 10)
      query.sliced?.should be_true
    end

    it "returns true if the query is not sliced" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.sliced?.should be_false
    end
  end

  describe "#to_empty" do
    it "results in a new EmptyQuery object" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.to_empty.should be_a Marten::DB::Query::SQL::EmptyQuery(Tag)
    end

    it "properly creates an empty query by respecting the default ordering" do
      query_1 = Marten::DB::Query::SQL::Query(Tag).new
      query_1.default_ordering = true
      query_1.to_empty.default_ordering.should be_true

      query_2 = Marten::DB::Query::SQL::Query(Tag).new
      query_2.default_ordering = false
      query_2.to_empty.default_ordering.should be_false
    end

    it "properly creates an empty query a query by respecting joins" do
      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_selected_join("author")

      query.to_empty.joins.should eq query.joins
    end

    it "properly creates an empty query by respecting limits and offsets" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("id")
      query.slice(1, 2)

      query.to_empty.limit.should eq query.limit
      query.to_empty.offset.should eq query.offset
    end

    it "properly creates an empty query by respecting order clauses" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.order("name")

      query.to_empty.order_clauses.should eq query.order_clauses
    end

    it "properly creates an empty query by respecting predicates" do
      query = Marten::DB::Query::SQL::Query(Tag).new
      query.add_query_node(Marten::DB::Query::Node.new(name__startswith: "r"))

      query.to_empty.predicate_node.should eq query.predicate_node
    end

    it "properly creates an empty query by respecting the active DB alias" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.using(:other).create!(name: "coding", is_active: true)

      query = Marten::DB::Query::SQL::Query(Tag).new
      query.using = "other"

      query.to_empty.using.should eq query.using
    end
  end

  describe "#update_with" do
    it "allows to update the records matching a given query and returns the number of affected rows" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.add_query_node(Marten::DB::Query::Node.new(first_name: "John"))
      query.update_with({"last_name" => "Updated", "is_admin" => true}).should eq 2

      user_1.reload
      user_1.first_name.should eq "John"
      user_1.last_name.should eq "Updated"
      user_1.is_admin.should be_true

      user_2.reload
      user_2.first_name.should eq "John"
      user_2.last_name.should eq "Updated"
      user_2.is_admin.should be_true

      user_3.reload
      user_3.first_name.should eq "Bob"
      user_3.last_name.should eq "Abc"
      user_3.is_admin.should be_falsey
    end

    it "is able to update a specific relation field" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "fix", email: "fix@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_3, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_3, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(author__username__startswith: "f"))
      query.update_with({"author" => user_1}).should eq 2

      post_1.reload
      post_1.author.should eq user_1

      post_2.reload
      post_2.author.should eq user_2

      post_3.reload
      post_3.author.should eq user_1
    end

    it "raises if the passed relation object is not persisted" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "fix", email: "fix@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")
      Post.create!(author: user_3, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(author__username__startswith: "f"))

      new_user = TestUser.new

      expect_raises(
        Marten::DB::Errors::UnexpectedFieldValue,
        "#{new_user} is not persisted and cannot be used in update queries"
      ) do
        query.update_with({"author" => new_user})
      end
    end

    it "returns 0 if no rows are updated" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      query = Marten::DB::Query::SQL::Query(TestUser).new
      query.add_query_node(Marten::DB::Query::Node.new(first_name: "Unknown"))
      query.update_with({:last_name => "Updated", :is_admin => true}).should eq 0

      user_1.reload
      user_1.first_name.should eq "John"
      user_1.last_name.should eq "Doe"
      user_1.is_admin.should be_falsey

      user_2.reload
      user_2.first_name.should eq "John"
      user_2.last_name.should eq "Bar"
      user_2.is_admin.should be_falsey

      user_3.reload
      user_3.first_name.should eq "Bob"
      user_3.last_name.should eq "Abc"
      user_3.is_admin.should be_falsey
    end

    it "allows to update records as expected when a query involves joins" do
      user_1 = TestUser.create!(username: "foo", email: "foo@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "bar", email: "bar@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "fix", email: "fix@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_3, title: "Post 3")

      query = Marten::DB::Query::SQL::Query(Post).new
      query.add_query_node(Marten::DB::Query::Node.new(author__username__startswith: "f"))
      query.update_with({"title" => "Updated"}).should eq 2

      post_1.reload
      post_1.title.should eq "Updated"

      post_2.reload
      post_2.title.should eq "Post 2"

      post_3.reload
      post_3.title.should eq "Updated"
    end

    context "with multi table inheritance" do
      it "can update local attributes seamlessly" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student_1 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query.add_query_node(Marten::DB::Query::Node.new(grade: "11"))
        query.update_with({"grade" => "11-updated"}).should eq 1

        student_1.reload
        student_1.grade.should eq "10"

        student_2.reload
        student_2.grade.should eq "11-updated"
      end

      it "can update parent attributes seamlessly" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student_1 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query.add_query_node(Marten::DB::Query::Node.new(grade: "11"))
        query.update_with({"name" => "Updated"}).should eq 1

        student_1.reload
        student_1.name.should eq "Student 1"

        student_2.reload
        student_2.name.should eq "Updated"
      end

      it "can update both local and parent attributes seamlessly" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student_1 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::Student.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::Student).new
        query.add_query_node(Marten::DB::Query::Node.new(grade: "11"))
        query.update_with({"name" => "Updated", "grade" => "11-updated"}).should eq 1

        student_1.reload
        student_1.name.should eq "Student 1"
        student_1.grade.should eq "10"

        student_2.reload
        student_2.name.should eq "Updated"
        student_2.grade.should eq "11-updated"
      end

      it "can update local attributes seamlessly with multiple levels of inheritance" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student_1 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11",
          alt_grade: "12"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query.add_query_node(Marten::DB::Query::Node.new(alt_grade: "12"))
        query.update_with({"alt_grade" => "12-updated"}).should eq 1

        student_1.reload
        student_1.alt_grade.should eq "11"

        student_2.reload
        student_2.alt_grade.should eq "12-updated"
      end

      it "can update parent attributes seamlessly with multiple levels of inheritance" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student_1 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11",
          alt_grade: "12"
        )

        query_1 = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query_1.add_query_node(Marten::DB::Query::Node.new(alt_grade: "12"))
        query_1.update_with({"name" => "Updated"}).should eq 1

        query_2 = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query_2.add_query_node(Marten::DB::Query::Node.new(alt_grade: "11"))
        query_2.update_with({"grade" => "10-updated"}).should eq 1

        student_1.reload
        student_1.name.should eq "Student 1"
        student_1.grade.should eq "10-updated"
        student_1.alt_grade.should eq "11"

        student_2.reload
        student_2.name.should eq "Updated"
        student_2.grade.should eq "11"
        student_2.alt_grade.should eq "12"
      end

      it "can update both local and parent attributes seamlessly with multiple levels of inheritance" do
        address = Marten::DB::Query::SQL::QuerySpec::Address.create!(street: "Street 1")
        student_1 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )
        student_2 = Marten::DB::Query::SQL::QuerySpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11",
          alt_grade: "12"
        )

        query = Marten::DB::Query::SQL::Query(Marten::DB::Query::SQL::QuerySpec::AltStudent).new
        query.add_query_node(Marten::DB::Query::Node.new(grade: "11"))
        query.update_with({"name" => "Updated", "grade" => "11-updated", "alt_grade" => "12-updated"}).should eq 1

        student_1.reload
        student_1.name.should eq "Student 1"
        student_1.grade.should eq "10"
        student_1.alt_grade.should eq "11"

        student_2.reload
        student_2.name.should eq "Updated"
        student_2.grade.should eq "11-updated"
        student_2.alt_grade.should eq "12-updated"
      end
    end
  end
end

class Post
  def __query_spec_author
    @author
  end

  def __query_spec_updated_by
    @updated_by
  end
end

class TestUser
  def __query_spec_profile
    @_reverse_o2o_profile
  end
end
