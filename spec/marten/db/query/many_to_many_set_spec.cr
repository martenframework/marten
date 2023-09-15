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

    it "adds the given array of records to the considered object's set of associated objects" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      user.tags.add([tag_1, tag_2])

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

      user.tags.using(:other).add([tag_1, tag_2])

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

  describe "#clear" do
    it "clears all the associated records from the many-to-many relationship when no other filters where defined" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag").add(tag_1, tag_2)
      Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag").add(tag_1, tag_2)

      Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag").clear

      qset_1 = Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag")
      qset_1.exists?.should be_false

      qset_2 = Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag")
      qset_2.all.to_set.should eq(Set{tag_1, tag_2})
    end

    it "clears only the right associated records from the many-to-many relationship when filters where defined" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag").add(tag_1, tag_2)
      Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag").add(tag_1, tag_2)

      Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag")
        .filter(name__endswith: "ing")
        .clear

      qset_1 = Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag")
      qset_1.all.to_a.should eq [tag_2]

      qset_2 = Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag")
      qset_2.all.to_set.should eq(Set{tag_1, tag_2})
    end

    it "does not clear any records from the many-to-many relationship is empty" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag").add(tag_1, tag_2)

      Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag").clear

      qset_1 = Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag")
      qset_1.exists?.should be_false

      qset_2 = Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag")
      qset_2.all.to_set.should eq(Set{tag_1, tag_2})
    end

    it "respects the specified connection alias" do
      user_1 = TestUser.new(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_1.save!(using: :other)
      user_2 = TestUser.new(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_2.save!(using: :other)

      tag_1 = Tag.new(name: "coding", is_active: true)
      tag_1.save!(using: :other)
      tag_2 = Tag.new(name: "crystal", is_active: true)
      tag_2.save!(using: :other)
      Tag.new(name: "ruby", is_active: true).save!(using: :other)

      Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag")
        .using(:other)
        .add(tag_1, tag_2)
      Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag")
        .using(:other)
        .add(tag_1, tag_2)

      Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag")
        .using(:other)
        .filter(name__endswith: "ing")
        .clear

      qset_1 = Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag")
      qset_1.using(:other).all.to_a.should eq [tag_2]

      qset_2 = Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag")
      qset_2.using(:other).all.to_set.should eq(Set{tag_1, tag_2})
    end

    it "resets cached records" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag").add(tag_1, tag_2)
      Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag").add(tag_1, tag_2)

      qset_1 = Marten::DB::Query::ManyToManySet(Tag).new(user_1, "tags", "testuser_tags", "testuser", "tag")

      qset_1.to_set.should eq(Set{tag_1, tag_2})

      qset_1.clear

      qset_1.to_a.should be_empty

      qset_2 = Marten::DB::Query::ManyToManySet(Tag).new(user_2, "tags", "testuser_tags", "testuser", "tag")
      qset_2.all.to_set.should eq(Set{tag_1, tag_2})
    end
  end

  describe "#remove" do
    it "removes a given record from the considered object's set of associated objects" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.add(tag_1, tag_2)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.all.to_set.should eq(Set{tag_1, tag_2})
      qset.remove(tag_1)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.all.to_set.should eq(Set{tag_2})
    end

    it "removes multiple records from the considered object's set of associated objects" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.add(tag_1, tag_2)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.all.to_set.should eq(Set{tag_1, tag_2})
      qset.remove(tag_1, tag_2)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.exists?.should be_false
    end

    it "ignores records that are not in the considered object's set of associated objects" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.add(tag_1, tag_2)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.remove(tag_3)
      qset.all.to_set.should eq(Set{tag_1, tag_2})
    end

    it "removes the given array of records from the considered object's set of associated objects" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "syntax", is_active: true)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.add(tag_1, tag_2, tag_4)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.all.to_set.should eq(Set{tag_1, tag_2, tag_4})
      qset.remove([tag_1, tag_4])

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.all.to_set.should eq(Set{tag_2})
    end

    it "respects the specified connection alias" do
      user = TestUser.new(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user.save!(using: :other)

      tag_1 = Tag.new(name: "coding", is_active: true)
      tag_1.save!(using: :other)
      tag_2 = Tag.new(name: "crystal", is_active: true)
      tag_2.save!(using: :other)
      Tag.new(name: "ruby", is_active: true).save!(using: :other)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag").using(:other)
      qset.add(tag_1, tag_2)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag").using(:other)
      qset.all.to_set.should eq(Set{tag_1, tag_2})
      qset.remove(tag_1)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag").using(:other)
      qset.all.to_set.should eq(Set{tag_2})
    end

    it "resets cached records" do
      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")
      qset.add(tag_1, tag_2)

      qset = Marten::DB::Query::ManyToManySet(Tag).new(user, "tags", "testuser_tags", "testuser", "tag")

      qset.to_set.should eq(Set{tag_1, tag_2})

      qset.remove(tag_1)

      qset.to_a.should eq [tag_2]
    end
  end
end
