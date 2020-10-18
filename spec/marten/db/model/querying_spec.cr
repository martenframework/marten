require "./spec_helper"

describe Marten::DB::Model::Querying do
  describe "::all" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")
    end

    it "returns a queryset containing all the objects matched by the default scope" do
      qs = TestUser.all
      qs.all.should be_a(Marten::DB::QuerySet(TestUser))

      results = qs.all.to_a
      results.size.should eq 2
      results.includes?(TestUser.get!(username: "jd1")).should be_true
      results.includes?(TestUser.get!(username: "foo")).should be_true
    end
  end
end
