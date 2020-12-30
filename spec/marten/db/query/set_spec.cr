require "./spec_helper"

describe Marten::DB::Query::Set do
  describe "#[]" do
    it "returns the expected record for a given index when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[1].should eq tag_2
    end

    it "returns the expected record for a given index when the query set already fetched the records" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[0].should eq tag_1
      qset[1].should eq tag_2
      qset[2].should eq tag_3
      qset[3].should eq tag_4
    end

    it "returns the expected records for a given range when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[1..3].to_a.should eq [tag_2, tag_3, tag_4]
    end

    it "returns the expected records for a given range when the query set already fetched the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[1..3].should eq [tag_2, tag_3, tag_4]
    end

    it "returns the expected records for an exclusive range when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[1...3].to_a.should eq [tag_2, tag_3]
    end

    it "returns the expected records for an exclusive range when the query set already fetched the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[1...3].should eq [tag_2, tag_3]
    end

    it "returns the expected records for a begin-less range when the query set didn't already fetch the records" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[..3].to_a.should eq [tag_1, tag_2, tag_3, tag_4]
    end

    it "returns the expected records for a begin-less range when the query set already fetched the records" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[..3].should eq [tag_1, tag_2, tag_3, tag_4]
    end

    it "returns the expected records for an end-less range when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[2..].to_a.should eq [tag_3, tag_4, tag_5]
    end

    it "returns the expected records for an end-less range when the query set already fetched the records" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[2..].to_a.should eq [tag_3, tag_4, tag_5]
    end

    it "raises if the specified index is negative" do
      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
        Marten::DB::Query::Set(Tag).new.order(:id)[-1]
      end
    end

    it "raises if the specified range has a negative beginning" do
      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
        Marten::DB::Query::Set(Tag).new.order(:id)[-1..10]
      end
    end

    it "raises if the specified range has a negative end" do
      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
        Marten::DB::Query::Set(Tag).new.order(:id)[10..-1]
      end
    end

    it "raises IndexError the specified index is out of bound when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)

      expect_raises(IndexError) do
        Marten::DB::Query::Set(Tag).new.all[20]
      end
    end

    it "raises IndexError the specified index is out of bound when the query set already fetched the records" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)

      expect_raises(IndexError) do
        qset = Marten::DB::Query::Set(Tag).new.all
        qset.each { }
        qset[20]
      end
    end
  end

  describe "#[]?" do
    it "returns the expected record for a given index when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[1]?.should eq tag_2
    end

    it "returns the expected record for a given index when the query set already fetched the records" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[0]?.should eq tag_1
      qset[1]?.should eq tag_2
      qset[2]?.should eq tag_3
      qset[3]?.should eq tag_4
    end

    it "returns the expected records for a given range when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[1..3]?.not_nil!.to_a.should eq [tag_2, tag_3, tag_4]
    end

    it "returns the expected records for a given range when the query set already fetched the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[1..3]?.should eq [tag_2, tag_3, tag_4]
    end

    it "returns the expected records for a begin-less range when the query set didn't already fetch the records" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[..3]?.not_nil!.to_a.should eq [tag_1, tag_2, tag_3, tag_4]
    end

    it "returns the expected records for an exclusive range when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[1...3]?.not_nil!.to_a.should eq [tag_2, tag_3]
    end

    it "returns the expected records for an exclusive range when the query set already fetched the records" do
      Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[1...3]?.not_nil!.should eq [tag_2, tag_3]
    end

    it "returns the expected records for a begin-less range when the query set already fetched the records" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[..3]?.not_nil!.should eq [tag_1, tag_2, tag_3, tag_4]
    end

    it "returns the expected records for an end-less range when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)

      qset[2..]?.not_nil!.to_a.should eq [tag_3, tag_4, tag_5]
    end

    it "returns the expected records for an end-less range when the query set already fetched the records" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)
      tag_5 = Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:id)
      qset.each { }

      qset[2..]?.not_nil!.to_a.should eq [tag_3, tag_4, tag_5]
    end

    it "raises if the specified index is negative" do
      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
        Marten::DB::Query::Set(Tag).new.order(:id)[-1]?
      end
    end

    it "raises if the specified range has a negative beginning" do
      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
        Marten::DB::Query::Set(Tag).new.order(:id)[-1..10]?
      end
    end

    it "raises if the specified range has a negative end" do
      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
        Marten::DB::Query::Set(Tag).new.order(:id)[10..-1]?
      end
    end

    it "returns nil if the specified index is out of bound when the query set didn't already fetch the records" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)

      Marten::DB::Query::Set(Tag).new.all[20]?.should be_nil
    end

    it "returns nil the specified index is out of bound when the query set already fetched the records" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.all
      qset.each { }

      qset[20]?.should be_nil
    end
  end

  describe "#all" do
    it "returns a clone of the current query set" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)

      qset_1 = Marten::DB::Query::Set(Tag).new
      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name__startswith: "c")

      new_qset_1 = qset_1.all
      new_qset_1.to_a.should eq [tag_1, tag_2]
      new_qset_1.object_id.should_not eq qset_1.object_id

      new_qset_2 = qset_2.all
      new_qset_2.to_a.should eq [tag_2]
      new_qset_2.object_id.should_not eq qset_2.object_id
    end
  end

  describe "#count" do
    it "returns the expected number of record for an unfiltered query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::Set(Tag).new.count.should eq 3
    end

    it "returns the expected number of record for a filtered query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c).count.should eq 2
      Marten::DB::Query::Set(Tag).new.filter(name__startswith: "r").count.should eq 1
      Marten::DB::Query::Set(Tag).new.filter(name__startswith: "x").count.should eq 0
    end
  end

  describe "#create" do
    it "returns the non-persisted model instance if it is invalid" do
      tag = Marten::DB::Query::Set(Tag).new.create(name: nil)
      tag.valid?.should be_false
      tag.persisted?.should be_false
    end

    it "returns the persisted model instance if it is valid" do
      tag = Marten::DB::Query::Set(Tag).new.create(name: "crystal", is_active: true)
      tag.valid?.should be_true
      tag.persisted?.should be_true
    end

    it "allows to initialize the new invalid object in a dedicated block" do
      tag = Marten::DB::Query::Set(Tag).new.create(is_active: nil) do |o|
        o.name = "ruby"
      end
      tag.name.should eq "ruby"
      tag.valid?.should be_false
      tag.persisted?.should be_false
    end

    it "allows to initialize the new valid object in a dedicated block" do
      tag = Marten::DB::Query::Set(Tag).new.create(is_active: true) do |o|
        o.name = "crystal"
      end
      tag.valid?.should be_true
      tag.persisted?.should be_true
    end

    it "properly uses the default connection as expected when no special connection is targetted" do
      tag_1 = Marten::DB::Query::Set(Tag).new.create(name: "crystal", is_active: true)

      tag_2 = Marten::DB::Query::Set(Tag).new.create(is_active: false) do |o|
        o.name = "ruby"
      end

      Marten::DB::Query::Set(Tag).new.to_a.should eq [tag_1, tag_2]
      Marten::DB::Query::Set(Tag).new.using(:other).to_a.should be_empty
    end

    it "properly uses the targetted connection as expected" do
      tag_1 = Marten::DB::Query::Set(Tag).new.using(:other).create(name: "crystal", is_active: true)

      tag_2 = Marten::DB::Query::Set(Tag).new.using(:other).create(is_active: false) do |o|
        o.name = "ruby"
      end

      Marten::DB::Query::Set(Tag).new.to_a.should be_empty
      Marten::DB::Query::Set(Tag).new.using(:other).to_a.should eq [tag_1, tag_2]
    end
  end

  describe "#create!" do
    it "raises InvalidRecord if the model instance is invalid" do
      expect_raises(Marten::DB::Errors::InvalidRecord) do
        Marten::DB::Query::Set(Tag).new.create!(name: nil)
      end
    end

    it "returns the persisted model instance if it is valid" do
      tag = Marten::DB::Query::Set(Tag).new.create!(name: "crystal", is_active: true)
      tag.valid?.should be_true
      tag.persisted?.should be_true
    end

    it "allows to initialize the new invalid object in a dedicated block" do
      expect_raises(Marten::DB::Errors::InvalidRecord) do
        Marten::DB::Query::Set(Tag).new.create!(is_active: nil) do |o|
          o.name = "ruby"
        end
      end
    end

    it "allows to initialize the new valid object in a dedicated block" do
      tag = Marten::DB::Query::Set(Tag).new.create!(is_active: true) do |o|
        o.name = "crystal"
      end
      tag.valid?.should be_true
      tag.persisted?.should be_true
    end

    it "properly uses the default connection as expected when no special connection is targetted" do
      tag_1 = Marten::DB::Query::Set(Tag).new.create!(name: "crystal", is_active: true)

      tag_2 = Marten::DB::Query::Set(Tag).new.create!(is_active: false) do |o|
        o.name = "ruby"
      end

      Marten::DB::Query::Set(Tag).new.to_a.should eq [tag_1, tag_2]
      Marten::DB::Query::Set(Tag).new.using(:other).to_a.should be_empty
    end

    it "properly uses the targetted connection as expected" do
      tag_1 = Marten::DB::Query::Set(Tag).new.using(:other).create!(name: "crystal", is_active: true)

      tag_2 = Marten::DB::Query::Set(Tag).new.using(:other).create!(is_active: false) do |o|
        o.name = "ruby"
      end

      Marten::DB::Query::Set(Tag).new.to_a.should be_empty
      Marten::DB::Query::Set(Tag).new.using(:other).to_a.should eq [tag_1, tag_2]
    end
  end

  describe "#delete" do
    it "allows to delete the records targetted by a specific query set" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c).delete.should eq 2

      Marten::DB::Query::Set(Tag).new.to_a.should eq [tag_1]
    end

    it "properly deletes records by respecting relationships" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      post_1 = Post.create!(author: user_1, title: "Post 1")
      post_2 = Post.create!(author: user_2, title: "Post 2")
      post_3 = Post.create!(author: user_1, title: "Post 3")

      ShowcasedPost.create!(post: post_1)
      showcased_post_2 = ShowcasedPost.create!(post: post_2)
      ShowcasedPost.create!(post: post_3)

      Marten::DB::Query::Set(TestUser).new.filter(id: user_1.id).delete.should eq 5

      TestUser.all.map(&.id).to_set.should eq [user_2.id].to_set
      Post.all.map(&.id).should eq [post_2.id]
      ShowcasedPost.all.map(&.id).should eq [showcased_post_2.id]
    end

    it "is able to perform raw deletions" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c).delete(raw: true).should eq 2

      Marten::DB::Query::Set(Tag).new.to_a.should eq [tag_1]
    end

    it "raises if the query set is sliced" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Delete with sliced queries is not supported") do
        Marten::DB::Query::Set(Tag).new[..1].as?(Marten::DB::Query::Set(Tag)).not_nil!.delete
      end
    end

    it "raises if the query set involves joins" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Example post")

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Delete with joins is not supported") do
        Marten::DB::Query::Set(Post).new.join(:author).delete
      end
    end
  end

  describe "#each" do
    it "allows to iterate over the records targetted by the query set if it wasn't already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      tags = [] of Tag

      Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c).each do |t|
        tags << t
      end

      tags.should eq [tag_2, tag_3]
    end

    it "allows to iterate over the records targetted by the query set if it was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      tags = [] of Tag

      qset = Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c)
      qset.each { }

      qset.each do |t|
        tags << t
      end

      tags.should eq [tag_2, tag_3]
    end
  end
end
