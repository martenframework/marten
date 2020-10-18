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
    it "returns a queryset without the objects matching the excluding predicates" do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")

      qs = TestUser.exclude(username: "foo")
      qs.should be_a(Marten::DB::QuerySet(TestUser))

      results = qs.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "jd2")).should be_true
    end

    it "makes use of the default queryset" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: false)
      Tag.create!(name: "coding", is_active: true)

      qs = Tag.exclude(name: "coding")
      qs.should be_a(Marten::DB::QuerySet(Tag))

      results = qs.to_a
      results.size.should eq 1
      results[0].should eq Tag.get!(name: "crystal")
    end
  end
end
