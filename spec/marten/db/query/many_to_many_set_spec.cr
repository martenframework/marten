require "./spec_helper"

describe Marten::DB::Query::ManyToManySet do
  describe "#all" do
    it "returns all the related records associated with the considered object" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)

      user_1.tags.add(tag_1)
      user_1.tags.add(tag_2)
      user_2.tags.add(tag_3)

      qset_1 = Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag")
      qset_1.all.to_set.should eq(Set{tag_1, tag_2})

      qset_2 = Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag")
      qset_2.all.to_a.should eq [tag_3]
    end
  end

  describe "#add" do
    it "adds the given records to the considered object's set of associated objects" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      user.tags.add(tag_1)
      user.tags.add(tag_2)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.all.to_set.should eq(Set{tag_1, tag_2})
    end

    it "does not add records that are already in the considered object's set of associated objects" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      user.tags.add(tag_1)
      user.tags.add(tag_2)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.all.to_set.should eq(Set{tag_1, tag_2})

      user.tags.add(tag_1)
      user.tags.add(tag_2)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.all.to_set.should eq(Set{tag_1, tag_2})
    end

    it "respects the specified connection alias" do
      user = TestUser.new(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user.save!(using: :other)

      tag_1 = Tag.new(name: "coding", is_active: true)
      tag_1.save!(using: :other)
      tag_2 = Tag.new(name: "crystal", is_active: true)
      tag_2.save!(using: :other)
      Tag.new(name: "ruby", is_active: true).save!(using: :other)

      user.tags.using(:other).add(tag_1, tag_2)

      qset_1 = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset_1.exists?.should be_false

      qset_2 = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset_2.using(:other).all.to_set.should eq(Set{tag_1, tag_2})
    end

    it "resets cached records" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.add(tag_1)

      qset.to_a.should eq [tag_1]

      qset.add(tag_2)

      qset.to_set.should eq(Set{tag_1, tag_2})
    end
  end
end
