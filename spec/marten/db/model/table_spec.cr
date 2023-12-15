require "./spec_helper"
require "./table_spec/app"

describe Marten::DB::Model::Table do
  with_installed_apps Marten::DB::Model::TableSpec::App

  describe "::finished" do
    it "allows abstract models without pk field" do
      Marten::DB::Model::TableSpec::AbstractModelWithoutPrimaryKey.fields.find(&.primary_key?).should be_nil
    end
  end

  describe "::inherited" do
    it "ensures that the model inherits its parent fields" do
      Marten::DB::Model::TableSpec::Article.local_fields.size.should eq 9
      Marten::DB::Model::TableSpec::Article.local_fields.map(&.id).should eq(
        [
          "created_at",
          "updated_at",
          "id",
          "author_id",
          "moderator_id",
          "title",
          "content",
          "tags",
          "additional_content",
        ]
      )
    end

    it "ensures that the model inherits its parent indexes" do
      Marten::DB::Model::TableSpec::Article.db_indexes.size.should eq 2
      Marten::DB::Model::TableSpec::Article.db_indexes.map(&.name).should eq(
        ["base_author_title_index", "other_author_title_index"]
      )
    end

    it "ensures that the model inherits its parent unique constraints" do
      Marten::DB::Model::TableSpec::Article.db_unique_constraints.size.should eq 2
      Marten::DB::Model::TableSpec::Article.db_unique_constraints.map(&.name).should eq(
        ["base_author_title_constraint", "other_author_title_constraint"]
      )
    end

    it "produces models that can be used to create records" do
      author = Marten::DB::Model::TableSpec::Author.create!(name: "Author")
      moderator = Marten::DB::Model::TableSpec::Author.create!(name: "Moderator")

      article = Marten::DB::Model::TableSpec::Article.create!(
        title: "Article 1",
        content: "Article content 1",
        additional_content: "Article additional content 1",
        author: author,
        moderator: moderator
      )
      article.persisted?.should be_true

      Marten::DB::Model::TableSpec::Article.all.to_a.should eq [article]
    end

    it "produces models that can be used to create records with many to one fields" do
      author = Marten::DB::Model::TableSpec::Author.create!(name: "Author")
      moderator = Marten::DB::Model::TableSpec::Author.create!(name: "Moderator")

      article = Marten::DB::Model::TableSpec::Article.create!(
        title: "Article 1",
        content: "Article content 1",
        additional_content: "Article additional content 1",
        author: author,
        moderator: moderator
      )
      article.persisted?.should be_true

      author.articles.to_a.should eq [article]
    end

    it "produces models that can be used to create records with one to one fields" do
      author = Marten::DB::Model::TableSpec::Author.create!(name: "Author")
      moderator = Marten::DB::Model::TableSpec::Author.create!(name: "Moderator")

      article = Marten::DB::Model::TableSpec::Article.create!(
        title: "Article 1",
        content: "Article content 1",
        additional_content: "Article additional content 1",
        author: author,
        moderator: moderator
      )
      article.persisted?.should be_true

      moderator.moderated_article.should eq article
    end

    it "produces models that can be used to create records with many many one fields" do
      author = Marten::DB::Model::TableSpec::Author.create!(name: "Author")
      moderator = Marten::DB::Model::TableSpec::Author.create!(name: "Moderator")

      tag_1 = Marten::DB::Model::TableSpec::Tag.create!(name: "t1")
      tag_2 = Marten::DB::Model::TableSpec::Tag.create!(name: "t2")

      article = Marten::DB::Model::TableSpec::Article.create!(
        title: "Article 1",
        content: "Article content 1",
        additional_content: "Article additional content 1",
        author: author,
        moderator: moderator
      )
      article.persisted?.should be_true

      article.tags.add(tag_1)
      article.tags.add(tag_2)

      article.tags.to_a.should eq [tag_1, tag_2]
      tag_1.articles.to_a.should eq [article]
    end

    context "with multiple table inheritance" do
      it "contributes a pointer one-to-one field to the child models" do
        field_1 = Marten::DB::Model::TableSpec::Student.get_field(:person_ptr)
        field_1.should be_a Marten::DB::Field::OneToOne
        field_1 = field_1.as(Marten::DB::Field::OneToOne)
        field_1.id.should eq "person_ptr_id"
        field_1.relation_name.should eq "person_ptr"
        field_1.related_model.should eq Marten::DB::Model::TableSpec::Person
        field_1.primary_key?.should be_true
        field_1.parent_link?.should be_true
        field_1.on_delete.should eq Marten::DB::Deletion::Strategy::CASCADE

        field_2 = Marten::DB::Model::TableSpec::AltStudent.get_field(:student_ptr)
        field_2.should be_a Marten::DB::Field::OneToOne
        field_2 = field_2.as(Marten::DB::Field::OneToOne)
        field_2.id.should eq "student_ptr_id"
        field_2.relation_name.should eq "student_ptr"
        field_2.related_model.should eq Marten::DB::Model::TableSpec::Student
        field_2.primary_key?.should be_true
        field_2.parent_link?.should be_true
        field_2.on_delete.should eq Marten::DB::Deletion::Strategy::CASCADE
      end

      it "contributes reverse relations on parent models" do
        address = Marten::DB::Model::TableSpec::Address.create!(street: "Street 1")

        student = Marten::DB::Model::TableSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )
        person = Marten::DB::Model::TableSpec::Person.get!(id: student.id)
        person.student.should eq student

        alt_student = Marten::DB::Model::TableSpec::AltStudent.create!(
          name: "Student 2",
          email: "student-2@example.com",
          address: address,
          grade: "11",
          alt_grade: "12"
        )
        other_student = Marten::DB::Model::TableSpec::Student.get!(id: alt_student.id)
        other_student.alt_student.should eq alt_student
        person = Marten::DB::Model::TableSpec::Person.get!(id: alt_student.id)
        person.student.should eq other_student
      end

      it "produces child models that can create properties of parent models seamlessly" do
        address = Marten::DB::Model::TableSpec::Address.create!(street: "Street 1")
        student = Marten::DB::Model::TableSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        student.persisted?.should be_true
        student.id.should_not be_nil
        student.pk.should_not be_nil
        student.person_ptr_id.should eq student.id
        student.name.should eq "Student 1"
        student.email.should eq "student-1@example.com"
        student.address.should eq address
        student.grade.should eq "10"

        student.reload
        student.id.should_not be_nil
        student.pk.should_not be_nil
        student.person_ptr_id.should eq student.id
        student.name.should eq "Student 1"
        student.email.should eq "student-1@example.com"
        student.address.should eq address
        student.grade.should eq "10"
      end

      it "produces child models that can create properties of parent models with multiple levels of inheritance" do
        address = Marten::DB::Model::TableSpec::Address.create!(street: "Street 1")
        alt_student = Marten::DB::Model::TableSpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )

        alt_student.persisted?.should be_true
        alt_student.id.should_not be_nil
        alt_student.pk.should_not be_nil
        alt_student.student_ptr_id.should eq alt_student.id
        alt_student.person_ptr_id.should eq alt_student.id
        alt_student.name.should eq "Student 1"
        alt_student.email.should eq "student-1@example.com"
        alt_student.address.should eq address
        alt_student.grade.should eq "10"
        alt_student.alt_grade.should eq "11"

        alt_student.reload
        alt_student.id.should_not be_nil
        alt_student.pk.should_not be_nil
        alt_student.student_ptr_id.should eq alt_student.id
        alt_student.person_ptr_id.should eq alt_student.id
        alt_student.name.should eq "Student 1"
        alt_student.email.should eq "student-1@example.com"
        alt_student.address.should eq address
        alt_student.grade.should eq "10"
        alt_student.alt_grade.should eq "11"
      end
    end
  end

  describe "::db_index" do
    it "allows to configure new index" do
      indexes = Post.db_indexes
      indexes.size.should eq 1
      indexes[0].name.should eq "author_title_index"
      indexes[0].fields.size.should eq 2
      indexes[0].fields[0].id.should eq "author_id"
      indexes[0].fields[1].id.should eq "title"
    end

    it "raises if the passed field does not correspond to any of the model's fields" do
      expect_raises(
        Marten::DB::Errors::UnknownField,
        "Unknown field 'unknown' in index definition"
      ) do
        Post.db_index("new_unique", ["unknown", "author"])
      end
    end
  end

  describe "::db_indexes" do
    it "returns an empty array if no indexes are defined" do
      TestUser.db_indexes.should be_empty
    end

    it "returns an array of the configured indexes" do
      indexes = Post.db_indexes
      indexes.size.should eq 1
      indexes[0].name.should eq "author_title_index"
      indexes[0].fields.size.should eq 2
      indexes[0].fields[0].id.should eq "author_id"
      indexes[0].fields[1].id.should eq "title"
    end
  end

  describe "::db_table" do
    it "returns the name of the model table based on the class name by default" do
      TestUser.db_table.should eq "app_test_user"
    end

    it "does not append a s characters if model names already end by one" do
      PostTags.db_table.should eq "app_post_tags"
    end

    it "returns the configured table name if applicable" do
      Post.db_table.should eq "posts"
    end
  end

  describe "::db_table(name)" do
    it "allows to configure the model table name" do
      Post.db_table.should eq "posts"
    end
  end

  describe "::db_unique_constraint" do
    it "allows to configure new unique constraints" do
      unique_constraints = Post.db_unique_constraints
      unique_constraints.size.should eq 1
      unique_constraints[0].name.should eq "author_title_constraint"
      unique_constraints[0].fields.size.should eq 2
      unique_constraints[0].fields[0].id.should eq "author_id"
      unique_constraints[0].fields[1].id.should eq "title"
    end

    it "raises if the passed field does not correspond to any of the model's fields" do
      expect_raises(
        Marten::DB::Errors::UnknownField,
        "Unknown field 'unknown' in unique constraint definition"
      ) do
        Post.db_unique_constraint("new_unique", ["unknown", "author"])
      end
    end
  end

  describe "::db_unique_constraints" do
    it "returns an empty array if no unique constraints are defined" do
      TestUser.db_unique_constraints.should be_empty
    end

    it "returns an array of the configured unique constraints when unique constraints are defined" do
      unique_constraints = Post.db_unique_constraints
      unique_constraints.size.should eq 1
      unique_constraints[0].name.should eq "author_title_constraint"
      unique_constraints[0].fields.size.should eq 2
      unique_constraints[0].fields[0].id.should eq "author_id"
      unique_constraints[0].fields[1].id.should eq "title"
    end
  end

  describe "::fields" do
    it "returns the field instances associated with the considered model class" do
      Tag.fields.size.should eq 3
      Tag.fields.map(&.id).should eq ["id", "name", "is_active"]
    end

    it "includes the field instances associated with parent model classes" do
      Marten::DB::Model::TableSpec::Student.fields.size.should eq 6
      Marten::DB::Model::TableSpec::Student.fields.map(&.id).should eq(
        ["id", "name", "email", "address_id", "person_ptr_id", "grade"]
      )
    end
  end

  describe "::get_field" do
    it "allows to retrieve a specific model fields from an ID string" do
      field = Tag.get_field("name")
      field.should be_a Marten::DB::Field::String
      field.id.should eq "name"
    end

    it "allows to retrieve a specific model fields from an ID symbol" do
      field = Tag.get_field(:name)
      field.should be_a Marten::DB::Field::String
      field.id.should eq "name"
    end

    it "allows to retrieve a specific model fields from a relation name" do
      field = Post.get_field(:author)
      field.should be_a Marten::DB::Field::ManyToOne
      field.id.should eq "author_id"
    end

    it "allows to retrieve a field from a parent model" do
      field_1 = Marten::DB::Model::TableSpec::Student.get_field(:name)
      field_1.should be_a Marten::DB::Field::String
      field_1.id.should eq "name"

      field_2 = Marten::DB::Model::TableSpec::AltStudent.get_field(:name)
      field_2.should be_a Marten::DB::Field::String
      field_2.id.should eq "name"
    end

    it "allows to retrieve a field from a parent model using a relation name" do
      field = Marten::DB::Model::TableSpec::Student.get_field(:address)
      field.should be_a Marten::DB::Field::ManyToOne
      field.id.should eq "address_id"
    end

    it "raises if the field cannot be found" do
      expect_raises(Marten::DB::Errors::UnknownField) do
        Tag.get_field(:unknown)
      end
    end
  end

  describe "::get_local_field" do
    it "allows to retrieve a specific model fields from an ID string" do
      field = Tag.get_local_field("name")
      field.should be_a Marten::DB::Field::String
      field.id.should eq "name"
    end

    it "allows to retrieve a specific model fields from an ID symbol" do
      field = Tag.get_local_field(:name)
      field.should be_a Marten::DB::Field::String
      field.id.should eq "name"
    end

    it "allows to retrieve a specific model fields from a relation name" do
      field = Post.get_local_field(:author)
      field.should be_a Marten::DB::Field::ManyToOne
      field.id.should eq "author_id"
    end

    it "raises if the field cannot be found" do
      expect_raises(Marten::DB::Errors::UnknownField) do
        Tag.get_local_field(:unknown)
      end
    end

    it "raises when trying to retrieve a field from a parent model" do
      expect_raises(Marten::DB::Errors::UnknownField) do
        Marten::DB::Model::TableSpec::Student.get_local_field(:name)
      end
    end

    it "raises when trying to retrieve a field from a parent model using a relation name" do
      expect_raises(Marten::DB::Errors::UnknownField) do
        Marten::DB::Model::TableSpec::Student.get_local_field(:address)
      end
    end
  end

  describe "::local_fields" do
    it "returns the field instances associated with the considered model class" do
      Tag.local_fields.size.should eq 3
      Tag.local_fields.map(&.id).should eq ["id", "name", "is_active"]
    end

    it "does not include the field instances associated with parent model classes" do
      Marten::DB::Model::TableSpec::Student.local_fields.size.should eq 2
      Marten::DB::Model::TableSpec::Student.local_fields.map(&.id).should eq ["person_ptr_id", "grade"]
      Marten::DB::Model::TableSpec::AltStudent.local_fields.map(&.id).should eq ["student_ptr_id", "alt_grade"]
    end
  end

  describe "::parent_models" do
    it "returns an empty array for models without parent models" do
      Tag.parent_models.should be_empty
    end

    it "returns an array of the parent models for models with parent models" do
      Marten::DB::Model::TableSpec::Student.parent_models.should eq [Marten::DB::Model::TableSpec::Person]
      Marten::DB::Model::TableSpec::AltStudent.parent_models.should eq(
        [Marten::DB::Model::TableSpec::Student, Marten::DB::Model::TableSpec::Person]
      )
    end
  end

  describe "::with_timestamp_fields" do
    it "adds the expected fields to the model" do
      created_at_field = Marten::DB::Model::TableSpec::BaseArticle.get_field("created_at")
      created_at_field.should be_a Marten::DB::Field::DateTime
      created_at_field.as(Marten::DB::Field::DateTime).auto_now_add?.should be_true
      created_at_field.as(Marten::DB::Field::DateTime).auto_now?.should be_false

      updated_at_field = Marten::DB::Model::TableSpec::BaseArticle.get_field("updated_at")
      updated_at_field.should be_a Marten::DB::Field::DateTime
      updated_at_field.as(Marten::DB::Field::DateTime).auto_now?.should be_true
      updated_at_field.as(Marten::DB::Field::DateTime).auto_now_add?.should be_false
    end
  end

  describe "#get_field_value" do
    it "returns the value of a specific model instance field" do
      tag = Tag.new(name: "crystal")
      tag.get_field_value("name").should eq "crystal"
    end

    it "can support field names expressed as symbols" do
      tag = Tag.new(name: "crystal")
      tag.get_field_value(:name).should eq "crystal"
    end

    it "raises if the field cannot be found" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnknownField) do
        tag.get_field_value(:unknown)
      end
    end
  end

  describe "#get_relation" do
    it "returns the relation record corresponding to the passed string" do
      address = Marten::DB::Model::TableSpec::Address.create!(street: "Street 1")
      student = Marten::DB::Model::TableSpec::Student.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
        grade: "10"
      )

      student.get_relation("address").should eq address
    end

    it "returns the relation record corresponding to the passed symbol" do
      address = Marten::DB::Model::TableSpec::Address.create!(street: "Street 1")
      student = Marten::DB::Model::TableSpec::Student.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
        grade: "10"
      )

      student.get_relation(:address).should eq address
    end

    it "returns nil if the corresponding field has no value yet" do
      student = Marten::DB::Model::TableSpec::Student.new(
        name: "Student 1",
        email: "student-1@example.com",
        grade: "10"
      )

      student.get_relation(:address).should be_nil
    end

    it "raises if the relation name does not correspond to any model relation" do
      address = Marten::DB::Model::TableSpec::Address.create!(street: "Street 1")
      student = Marten::DB::Model::TableSpec::Student.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
        grade: "10"
      )

      expect_raises(Marten::DB::Errors::UnknownField) do
        student.get_relation(:unknown)
      end
    end
  end

  describe "#pk" do
    it "returns the primary key field value" do
      tag = Marten::DB::Model::TableSpec::Tag.create!(name: "crystal")

      tag.pk.should_not be_nil
      tag.pk.should eq tag.id
    end

    it "returns the raw field value for a relationship field" do
      tag = Marten::DB::Model::TableSpec::Tag.create!(name: "crystal")
      wrapping_tag = Marten::DB::Model::TableSpec::WrappingTag.create!(tag: tag, details: "Test")

      wrapping_tag.pk.should_not be_nil
      wrapping_tag.pk.should eq tag.pk
    end

    it "returns nil if the primary key field has no value" do
      tag = Marten::DB::Model::TableSpec::Tag.new

      tag.pk.should be_nil
    end
  end

  describe "#pk?" do
    it "returns true if a primary key value is set on the record" do
      tag = Marten::DB::Model::TableSpec::Tag.create!(name: "crystal")

      tag.pk?.should be_true
    end

    it "returns false if a primary key value is not set on the record" do
      tag = Marten::DB::Model::TableSpec::Tag.new(name: "crystal")

      tag.pk?.should be_false
    end
  end

  describe "#pk!" do
    it "returns the primary key field value" do
      tag = Marten::DB::Model::TableSpec::Tag.create!(name: "crystal")

      tag.pk!.should_not be_nil
      tag.pk!.should eq tag.id
    end

    it "raises a NilAssertionError if the primary key field has no value" do
      tag = Marten::DB::Model::TableSpec::Tag.new

      expect_raises(NilAssertionError) { tag.pk! }
    end
  end

  describe "#pk=" do
    it "allows to set the primary key field value" do
      tag = Marten::DB::Model::TableSpec::Tag.create!(name: "crystal")

      tag.pk = 42
      tag.pk.should eq 42
    end
  end

  describe "#set_field_value" do
    it "allows to set the value of a specific model instance field" do
      tag = Tag.new(name: "crystal")
      tag.set_field_value("name", "ruby")
      tag.name.should eq "ruby"
    end

    it "can support field names expressed as symbols" do
      tag = Tag.new(name: "crystal")
      tag.set_field_value(:name, "ruby")
      tag.name.should eq "ruby"
    end

    it "raises if the field cannot be found" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnknownField) do
        tag.set_field_value(:unknown, "test")
      end
    end

    it "raises if the value type is invalid for the considered field type" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        tag.set_field_value(:name, 42)
      end
    end
  end

  describe "#set_field_values" do
    it "allows to set the value of specific model instance fields from keyword arguments" do
      tag = Tag.new(name: "crystal", is_active: false)
      tag.set_field_values(name: "updated", is_active: true)
      tag.name.should eq "updated"
      tag.is_active.should be_true
    end

    it "allows to set the value of specific model instance fields from a hash" do
      tag = Tag.new(name: "crystal", is_active: false)
      tag.set_field_values({"name" => "updated", "is_active" => true})
      tag.name.should eq "updated"
      tag.is_active.should be_true
    end

    it "allows to set the value of specific model instance fields from a named tuple" do
      tag = Tag.new(name: "crystal", is_active: false)
      tag.set_field_values({name: "updated", is_active: true})
      tag.name.should eq "updated"
      tag.is_active.should be_true
    end

    it "raises if a field cannot be found" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnknownField) do
        tag.set_field_values(name: "updated", unknown: "test")
      end
    end

    it "raises if a value type is invalid for the considered field type" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        tag.set_field_values(name: 42, is_active: true)
      end
    end
  end

  describe "#to_s" do
    it "returns the expected model instance representation" do
      tag = Tag.create!(name: "crystal", is_active: true)
      tag.to_s.should eq "#<Tag:0x#{tag.object_id.to_s(16)} id: #{tag.id}, name: \"crystal\", is_active: true>"
    end
  end

  describe "#inspect" do
    it "returns the expected model instance representation" do
      tag = Tag.create!(name: "crystal", is_active: true)
      tag.inspect.should eq "#<Tag:0x#{tag.object_id.to_s(16)} id: #{tag.id}, name: \"crystal\", is_active: true>"
    end
  end
end
