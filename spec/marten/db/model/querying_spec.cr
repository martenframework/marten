require "./spec_helper"

describe Marten::DB::Model::Querying do
  describe "::all" do
    it "returns a queryset containing all the objects matched by the default scope" do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      qs = TestUser.all
      qs.should be_a(Marten::DB::QuerySet(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "foo")).should be_true
    end

    it "returns a queryset containing all the objects matched by a custom default scope if applicable" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: false)
      Tag.create!(name: "coding", is_active: true)

      qs = Tag.all
      qs.should be_a(Marten::DB::QuerySet(Tag))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(Tag.get!(name: "crystal")).should be_true
      results.includes?(Tag.get!(name: "coding")).should be_true
    end
  end

  describe "::default_queryset" do
    it "returns a queryset containing all the objects by default" do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      qs = TestUser.default_queryset
      qs.should be_a(Marten::DB::QuerySet(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "foo")).should be_true
    end
  end

  describe "::exclude" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: false)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns a queryset without the objects matching the excluding predicates" do
      qs = TestUser.exclude(username: "foo")
      qs.should be_a(Marten::DB::QuerySet(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "jd2")).should be_true
    end

    it "makes use of the default queryset" do
      qs = Tag.exclude(name: "coding")
      qs.should be_a(Marten::DB::QuerySet(Tag))

      results = qs.to_a
      results.size.should eq 1
      results[0].should eq Tag.get!(name: "crystal")
    end

    it "returns a queryset without the objects matching the advanced predicates expression" do
      qs = TestUser.exclude { q(username: "foo") | q(username: "jd1") }
      qs.should be_a(Marten::DB::QuerySet(TestUser))

      results = qs.to_a
      results.size.should eq 1
      results[0].should eq TestUser.get(username: "jd2")
    end

    it "makes use of the default queryset when using a block defining an advanced predicates expression" do
      qs = Tag.exclude { q(name: "crystal") | q(name: "coding") }
      qs.should be_a(Marten::DB::QuerySet(Tag))

      results = qs.to_a
      results.size.should eq 0
    end
  end

  describe "::filter" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: false)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns a queryset with the objects matching the filter predicates" do
      qs = TestUser.filter(username__startswith: "jd")
      qs.should be_a(Marten::DB::QuerySet(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "jd2")).should be_true
    end

    it "makes use of the default queryset" do
      qs = Tag.filter(name: "coding")
      qs.should be_a(Marten::DB::QuerySet(Tag))

      results = qs.to_a
      results.size.should eq 1
      results[0].should eq Tag.get!(name: "coding")
    end

    it "returns a queryset with the objects matching the advanced predicates expression" do
      qs = TestUser.filter { q(username: "foo") | q(username: "jd1") }
      qs.should be_a(Marten::DB::QuerySet(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "foo")).should be_true
      results.includes?(TestUser.get!(username: "jd1")).should be_true
    end

    it "makes use of the default queryset when using a block defining an advanced predicates expression" do
      qs = Tag.filter { q(name__startswith: "cr") & q(name__endswith: "al") }
      qs.should be_a(Marten::DB::QuerySet(Tag))

      results = qs.to_a
      results.size.should eq 1
      results[0].should eq Tag.get!(name: "crystal")
    end
  end

  describe "::first" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: false)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns the first object" do
      TestUser.first.should eq TestUser.get!(username: "jd1")
    end

    it "makes use of the default queryset" do
      Tag.first.should eq Tag.get!(name: "ruby")
    end
  end

  describe "::get" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: false)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns the object corresponding to the passed simple predicates" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get(username: "jd3").should eq user
    end

    it "returns nil if the object does not exist" do
      TestUser.get(username: "unknown").should be_nil
    end

    it "raises if multiple records match the given predicates" do
      expect_raises(Marten::DB::Errors::MultipleRecordsFound) { TestUser.get(username__startswith: "jd") }
    end

    it "makes use of the default queryset" do
      tag = Tag.create!(name: "verbose", is_active: true)
      Tag.get(name: "verbose").should eq tag
      Tag.get(name: "crystal").should be_nil
    end

    it "returns the object matching the advanced predicates" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get { q(username__startswith: "jd") & q(username__endswith: "3") }.should eq user
    end

    it "makes use of the default queryset when using a block defining an advanced predicates expression" do
      Tag.get { q(name: "crystal") }.should be_nil
    end
  end

  describe "::get!" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      Tag.create!(name: "crystal", is_active: false)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "coding", is_active: true)
    end

    it "returns the object corresponding to the passed simple predicates" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get!(username: "jd3").should eq user
    end

    it "raises if the record is not found" do
      expect_raises(TestUser::NotFound) { TestUser.get!(username: "unknown") }
    end

    it "raises if multiple records match the given predicates" do
      expect_raises(Marten::DB::Errors::MultipleRecordsFound) { TestUser.get!(username__startswith: "jd") }
    end

    it "makes use of the default queryset" do
      tag = Tag.create!(name: "verbose", is_active: true)
      Tag.get!(name: "verbose").should eq tag
      expect_raises(Tag::NotFound) { Tag.get!(name: "crystal") }
    end

    it "returns the object matching the advanced predicates" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.get! { q(username__startswith: "jd") & q(username__endswith: "3") }.should eq user
    end

    it "makes use of the default queryset when using a block defining an advanced predicates expression" do
      expect_raises(Tag::NotFound) { Tag.get! { q(name: "crystal") } }
    end
  end
end
