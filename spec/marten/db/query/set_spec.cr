require "./spec_helper"
require "./set_spec/app"

describe Marten::DB::Query::Set do
  with_installed_apps Marten::DB::Query::SetSpec::App

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

  describe "#accumulate" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError) { Marten::DB::Query::Set(Tag).new.accumulate }
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

  describe "#any?" do
    it "returns true if the queryset matches existing records and if it wasn't already fetched" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::Set(Tag).new.all
      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name: "crystal")

      qset_1.any?.should be_true # ameba:disable Performance/AnyInsteadOfEmpty
      qset_2.any?.should be_true # ameba:disable Performance/AnyInsteadOfEmpty
    end

    it "returns true if the queryset matches existing records and if it was already fetched" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::Set(Tag).new.all
      qset_1.each { }

      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name: "crystal")
      qset_2.each { }

      qset_1.any?.should be_true # ameba:disable Performance/AnyInsteadOfEmpty
      qset_2.any?.should be_true # ameba:disable Performance/AnyInsteadOfEmpty
    end

    it "returns false if the queryset doesn't match existing records and if it wasn't already fetched" do
      qset_1 = Marten::DB::Query::Set(Tag).new.all
      qset_1.any?.should be_false # ameba:disable Performance/AnyInsteadOfEmpty

      Tag.create!(name: "crystal", is_active: true)

      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name: "ruby")
      qset_2.any?.should be_false # ameba:disable Performance/AnyInsteadOfEmpty
    end

    it "returns false if the queryset doesn't match existing records and if it was already fetched" do
      qset_1 = Marten::DB::Query::Set(Tag).new.all
      qset_1.each { }
      qset_1.any?.should be_false # ameba:disable Performance/AnyInsteadOfEmpty

      Tag.create!(name: "crystal", is_active: true)

      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name: "ruby")
      qset_2.each { }
      qset_2.any?.should be_false # ameba:disable Performance/AnyInsteadOfEmpty
    end
  end

  describe "#count" do
    it "returns the expected number of record for an unfiltered query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::Set(Tag).new.count.should eq 3
    end

    it "returns the expected number of results for an unfiltered query with specific column defined" do
      address = Marten::DB::Query::SetSpec::Address.create!(street: "Street 1")
      student = Marten::DB::Query::SetSpec::Student.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
        grade: "10"
      )

      Marten::DB::Query::SetSpec::Article.create!(title: "Top things", author: student)
      Marten::DB::Query::SetSpec::Article.create!(
        title: "Top things 2",
        subtitle: "Rise of the top things",
        author: student
      )
      Marten::DB::Query::SetSpec::Article.create!(
        title: "Top things 3",
        subtitle: "Top things awakening",
        author: student
      )

      Marten::DB::Query::Set(Marten::DB::Query::SetSpec::Article).new.count(:subtitle).should eq 2
    end

    it "returns the expected number of record for an unfiltered query set that was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.all
      qset.each { }

      qset.count.should eq 3
    end

    it "returns the expected number of record for a filtered query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c).count.should eq 2
      Marten::DB::Query::Set(Tag).new.filter(name__startswith: "r").count.should eq 1
      Marten::DB::Query::Set(Tag).new.filter(name__startswith: "x").count.should eq 0
    end

    it "returns the expected number of record for a filtered query set that was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c).all
      qset_1.each { }
      qset_1.count.should eq 2

      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name__startswith: "r").all
      qset_2.each { }
      qset_2.count.should eq 1

      qset_3 = Marten::DB::Query::Set(Tag).new.filter(name__startswith: "x").all
      qset_3.each { }
      qset_3.count.should eq 0
    end

    it "does not use cached records to do the count if a field is specified" do
      address = Marten::DB::Query::SetSpec::Address.create!(street: "Street 1")
      student = Marten::DB::Query::SetSpec::Student.create!(
        name: "Student 1",
        email: "student-1@example.com",
        address: address,
        grade: "10"
      )

      Marten::DB::Query::SetSpec::Article.create!(title: "Top things", author: student)
      Marten::DB::Query::SetSpec::Article.create!(
        title: "Top things 2",
        subtitle: "Rise of the top things",
        author: student
      )
      Marten::DB::Query::SetSpec::Article.create!(
        title: "Top things 3",
        subtitle: "Top things awakening",
        author: student
      )

      qset = Marten::DB::Query::Set(Marten::DB::Query::SetSpec::Article).new
      qset.each { }
      qset.count.should eq 3
      qset.count(:subtitle).should eq 2
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
        if (qset = Marten::DB::Query::Set(Tag).new[..1]).is_a?(Marten::DB::Query::Set(Tag))
          qset.delete
        end
      end
    end

    it "raises if the query set involves joins" do
      user = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      Post.create!(author: user, title: "Example post")

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Delete with joins is not supported") do
        Marten::DB::Query::Set(Post).new.join(:author).delete
      end
    end

    it "resets cached records" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c)

      qset.to_set.should eq(Set{tag_2, tag_3})

      qset.delete.should eq 2

      qset.to_a.should be_empty

      Marten::DB::Query::Set(Tag).new.to_a.should eq [tag_1]
    end

    context "with multi table inheritance" do
      it "deletes the targeted objects and their parents as expected" do
        address = Marten::DB::Query::SetSpec::Address.create!(street: "Street 2")

        Marten::DB::Query::SetSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        Marten::DB::Query::Set(Marten::DB::Query::SetSpec::Student).new.delete

        Marten::DB::Query::SetSpec::Student.get(name: "Student 1").should be_nil
        Marten::DB::Query::SetSpec::Person.get(name: "Student 1").should be_nil
      end

      it "deletes only the targeted objects and not their parents in raw mode" do
        address = Marten::DB::Query::SetSpec::Address.create!(street: "Street 2")

        Marten::DB::Query::SetSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        Marten::DB::Query::Set(Marten::DB::Query::SetSpec::Student).new.delete(raw: true)

        Marten::DB::Query::SetSpec::Student.get(name: "Student 1").should be_nil
        Marten::DB::Query::SetSpec::Person.get(name: "Student 1").should_not be_nil
      end

      it "deletes the targeted objects and their parents as expected with multiple levels of inheritance" do
        address = Marten::DB::Query::SetSpec::Address.create!(street: "Street 2")

        Marten::DB::Query::SetSpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )

        Marten::DB::Query::Set(Marten::DB::Query::SetSpec::AltStudent).new.delete

        Marten::DB::Query::SetSpec::AltStudent.get(name: "Student 1").should be_nil
        Marten::DB::Query::SetSpec::Student.get(name: "Student 1").should be_nil
        Marten::DB::Query::SetSpec::Person.get(name: "Student 1").should be_nil
      end

      it "deletes the only targeted objects and not their parents in raw mode with multiple levels of inheritance" do
        address = Marten::DB::Query::SetSpec::Address.create!(street: "Street 2")

        Marten::DB::Query::SetSpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )

        Marten::DB::Query::Set(Marten::DB::Query::SetSpec::AltStudent).new.delete(raw: true)

        Marten::DB::Query::SetSpec::AltStudent.get(name: "Student 1").should be_nil
        Marten::DB::Query::SetSpec::Student.get(name: "Student 1").should_not be_nil
        Marten::DB::Query::SetSpec::Person.get(name: "Student 1").should_not be_nil
      end
    end
  end

  describe "#distinct" do
    it "allows to return non-duplicated rows" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1", published: true)
      Post.create!(author: user_1, title: "Post 2", published: true)
      Post.create!(author: user_2, title: "Post 3", published: true)
      Post.create!(author: user_1, title: "Post 4", published: false)

      TestUser.filter(posts__published: true).distinct.size.should eq 2
      TestUser.filter(posts__published: true).distinct.to_set.should eq [user_1, user_2].to_set
    end

    it "raises if a slice was already configured for the query set" do
      expect_raises(
        Marten::DB::Errors::UnmetQuerySetCondition,
        "Distinct on sliced queries is not supported"
      ) do
        if (qset = Marten::DB::Query::Set(Tag).new[..1]).is_a?(Marten::DB::Query::Set(Tag))
          qset.distinct
        end
      end
    end
  end

  for_postgresql do
    describe "#distinct(*fields)" do
      it "allows to return non-duplicated rows based on a specific field expressed as a symbol" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.all.distinct(:first_name).size.should eq 2
        TestUser.all.distinct(:first_name).to_set.should eq [user_1, user_3].to_set
      end

      it "allows to return non-duplicated rows based on a specific field expressed as a string" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.all.distinct("first_name").size.should eq 2
        TestUser.all.distinct("first_name").to_set.should eq [user_1, user_3].to_set
      end

      it "allows to return non-duplicated rows based on multiple specific fields" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.all.distinct(:first_name, :last_name).size.should eq 2
        TestUser.all.distinct(:first_name, :last_name).to_set.should eq [user_1, user_3].to_set
      end

      it "allows to return non-duplicated rows based on a specific fields by following associations" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        post_1 = Post.create!(author: user_1, title: "Post 1", published: true)
        Post.create!(author: user_1, title: "Post 2", published: true)
        Post.create!(author: user_2, title: "Post 3", published: true)
        Post.create!(author: user_1, title: "Post 4", published: false)
        post_5 = Post.create!(author: user_3, title: "Post 4", published: false)

        Post.all.distinct(:author__first_name).size.should eq 2
        Post.all.distinct(:author__first_name).to_set.should eq [post_1, post_5].to_set
      end

      it "raises if a slice was already configured for the query set" do
        expect_raises(
          Marten::DB::Errors::UnmetQuerySetCondition,
          "Distinct on sliced queries is not supported"
        ) do
          if (qset = Marten::DB::Query::Set(Tag).new[..1]).is_a?(Marten::DB::Query::Set(Tag))
            qset.distinct(:name)
          end
        end
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

  describe "#exclude" do
    it "allows to exclude the records matching predicates expressed as keyword arguments" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.exclude(name__startswith: :r)

      qset.to_a.should eq [tag_2, tag_3, tag_4]
    end

    it "allows to exclude the records matching predicates expressed using a q expression" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.exclude { q(name__startswith: :r) | q(name: "programming") }.order(:id)

      qset.to_a.should eq [tag_2, tag_3]
    end

    it "allows to exclude the records matching predicates expressed using a query node object" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.exclude(Marten::DB::Query::Node.new(name__startswith: :r))

      qset.to_a.should eq [tag_2, tag_3, tag_4]
    end

    it "properly returns an empty query set if there are no other records" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::Set(Tag).new.exclude(name__startswith: :c)
      qset_2 = Marten::DB::Query::Set(Tag).new.exclude { q(name__startswith: :c) | q(name: "programming") }
      qset_3 = Marten::DB::Query::Set(Tag).new.exclude(Marten::DB::Query::Node.new(name__startswith: :c))

      qset_1.exists?.should be_false
      qset_1.to_a.should be_empty

      qset_2.exists?.should be_false
      qset_2.to_a.should be_empty

      qset_3.exists?.should be_false
      qset_3.to_a.should be_empty
    end
  end

  describe "#exists?" do
    it "returns true if the queryset matches existing records and if it wasn't already fetched" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::Set(Tag).new.all
      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name: "crystal")

      qset_1.exists?.should be_true
      qset_2.exists?.should be_true
    end

    it "returns true if the queryset matches existing records and if it was already fetched" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::Set(Tag).new.all
      qset_1.each { }

      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name: "crystal")
      qset_2.each { }

      qset_1.exists?.should be_true
      qset_2.exists?.should be_true
    end

    it "returns false if the queryset doesn't match existing records and if it wasn't already fetched" do
      qset_1 = Marten::DB::Query::Set(Tag).new.all
      qset_1.exists?.should be_false

      Tag.create!(name: "crystal", is_active: true)

      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name: "ruby")
      qset_2.exists?.should be_false
    end

    it "returns false if the queryset doesn't match existing records and if it was already fetched" do
      qset_1 = Marten::DB::Query::Set(Tag).new.all
      qset_1.each { }
      qset_1.exists?.should be_false

      Tag.create!(name: "crystal", is_active: true)

      qset_2 = Marten::DB::Query::Set(Tag).new.filter(name: "ruby")
      qset_2.each { }
      qset_2.exists?.should be_false
    end

    it "returns true if the specified filters matches at least one record" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Marten::DB::Query::Set(Tag).new.exists?(name: "crystal").should be_true
    end

    it "returns false if the specified filters does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Marten::DB::Query::Set(Tag).new.exists?(name: "ruby").should be_false
    end

    it "returns true if the passed q() expression matches at least one record" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Marten::DB::Query::Set(Tag).new.exists? { q(name: "crystal") }.should be_true
    end

    it "returns false if the passed q() expression does not match anythin" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Marten::DB::Query::Set(Tag).new.exists? { q(name: "ruby") }.should be_false
    end

    it "returns true if the passed query node matches at least one record" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Marten::DB::Query::Set(Tag).new.exists?(Marten::DB::Query::Node.new(name: "crystal")).should be_true
    end

    it "returns true if the passed query node does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Marten::DB::Query::Set(Tag).new.exists?(Marten::DB::Query::Node.new(name: "ruby")).should be_false
    end
  end

  describe "#filter" do
    it "allows to filter the records matching predicates expressed as keyword arguments" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c)

      qset.to_a.should eq [tag_2, tag_3]
    end

    it "allows to filter the records matching predicates expressed using a q expression" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.filter { q(name__startswith: :r) | q(name: "programming") }

      qset.to_a.should eq [tag_1, tag_4]
    end

    it "allows to filter the records matching predicates expressed using a query node object" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.filter(Marten::DB::Query::Node.new(name__startswith: :c))

      qset.to_a.should eq [tag_2, tag_3]
    end

    it "works as expected if the queryset was already fetched" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)
      tag_4 = Tag.create!(name: "programming", is_active: true)

      qset_1 = Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c)
      qset_1.each { }

      qset_2 = Marten::DB::Query::Set(Tag).new.filter { q(name__startswith: :r) | q(name: "programming") }
      qset_2.each { }

      qset_3 = Marten::DB::Query::Set(Tag).new.filter(Marten::DB::Query::Node.new(name__startswith: :c))
      qset_3.each { }

      qset_1.to_a.should eq [tag_2, tag_3]
      qset_2.to_a.should eq [tag_1, tag_4]
      qset_3.to_a.should eq [tag_2, tag_3]
    end
  end

  describe "#first" do
    it "returns the first result for an ordered queryset" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:name)

      qset.first.should eq tag_2
    end

    it "returns the first result ordered according to primary keys for an unordered queryset" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.first.should eq tag_1
    end

    it "returns nil if the queryset doesn't match any records" do
      qset = Marten::DB::Query::Set(Tag).new
      qset.first.should be_nil
    end
  end

  describe "#first!" do
    it "returns the first result for an ordered queryset" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:name)

      qset.first!.should eq tag_2
    end

    it "returns the first result ordered according to primary keys for an unordered queryset" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.first!.should eq tag_1
    end

    it "raises a NilAssertionError error if the queryset doesn't match any records" do
      qset = Marten::DB::Query::Set(Tag).new
      expect_raises(NilAssertionError) { qset.first!.should be_nil }
    end
  end

  describe "#get" do
    it "returns the record corresponding to predicates expressed as keyword arguments" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      tag_qset.get(name: "crystal").should eq tag
      tag_qset.get(name: "crystal", is_active: true).should eq tag

      user_qset.get(username: "jd1").should eq user
      user_qset.get(email: "jd1@example.com").should eq user
      user_qset.get(username: "jd1", first_name: "John").should eq user
    end

    it "returns the record corresponding to predicates expressed as q expressions" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      tag_qset.get { q(name: "crystal") }.should eq tag
      tag_qset.get { q(name: "crystal") & q(is_active: true) }.should eq tag

      user_qset.get { q(username: "jd1") }.should eq user
      user_qset.get { q(email: "jd1@example.com") }.should eq user
      user_qset.get { q(username: "jd1") & q(first_name: "John") }.should eq user
    end

    it "returns the record corresponding to predicates expressed using query node objects" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      tag_qset.get(Marten::DB::Query::Node.new(name: "crystal")).should eq tag
      tag_qset.get(Marten::DB::Query::Node.new(name: "crystal", is_active: true)).should eq tag

      user_qset.get(Marten::DB::Query::Node.new(username: "jd1")).should eq user
      user_qset.get(Marten::DB::Query::Node.new(email: "jd1@example.com")).should eq user
      user_qset.get(Marten::DB::Query::Node.new(username: "jd1", first_name: "John")).should eq user
    end

    it "returns nil if predicates expressed as keyword arguments does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      tag_qset.get(name: "ruby").should be_nil
      tag_qset.get(name: "crystal", is_active: false).should be_nil

      user_qset.get(username: "foo").should be_nil
      user_qset.get(username: "jd1", first_name: "Foo").should be_nil
    end

    it "returns nil if predicates expressed as q expressions does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      tag_qset.get { q(name: "ruby") }.should be_nil
      tag_qset.get { q(name: "crystal") & q(is_active: false) }.should be_nil

      user_qset.get { q(username: "foo") }.should be_nil
      user_qset.get { q(username: "jd1") & q(first_name: "Foo") }.should be_nil
    end

    it "returns nil if predicates expressed as query node objects does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      tag_qset.get(Marten::DB::Query::Node.new(name: "ruby")).should be_nil
      tag_qset.get(Marten::DB::Query::Node.new(name: "crystal", is_active: false)).should be_nil

      user_qset.get(Marten::DB::Query::Node.new(username: "foo")).should be_nil
      user_qset.get(Marten::DB::Query::Node.new(username: "jd1", first_name: "Foo")).should be_nil
    end

    it "raises if multiple records are found when using predicates expressed as keyword arguments" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        qset.get(name__startswith: "c")
      end
    end

    it "raises if multiple records are found when using predicates expressed as q expressions" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        qset.get { q(name__startswith: "c") & q(is_active: true) }
      end
    end

    it "raises if multiple records are found when using predicates expressed as query node objects" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        qset.get(Marten::DB::Query::Node.new(name__startswith: "c"))
      end
    end
  end

  describe "#get!" do
    it "returns the record corresponding to predicates expressed as keyword arguments" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      tag_qset.get!(name: "crystal").should eq tag
      tag_qset.get!(name: "crystal", is_active: true).should eq tag

      user_qset.get!(username: "jd1").should eq user
      user_qset.get!(email: "jd1@example.com").should eq user
      user_qset.get!(username: "jd1", first_name: "John").should eq user
    end

    it "returns the record corresponding to predicates expressed as q expressions" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      tag_qset.get! { q(name: "crystal") }.should eq tag
      tag_qset.get! { q(name: "crystal") & q(is_active: true) }.should eq tag

      user_qset.get! { q(username: "jd1") }.should eq user
      user_qset.get! { q(email: "jd1@example.com") }.should eq user
      user_qset.get! { q(username: "jd1") & q(first_name: "John") }.should eq user
    end

    it "returns the record corresponding to predicates expressed using query node objects" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      tag_qset.get!(Marten::DB::Query::Node.new(name: "crystal")).should eq tag
      tag_qset.get!(Marten::DB::Query::Node.new(name: "crystal", is_active: true)).should eq tag

      user_qset.get!(Marten::DB::Query::Node.new(username: "jd1")).should eq user
      user_qset.get!(Marten::DB::Query::Node.new(email: "jd1@example.com")).should eq user
      user_qset.get!(Marten::DB::Query::Node.new(username: "jd1", first_name: "John")).should eq user
    end

    it "raises if predicates expressed as keyword arguments does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      expect_raises(Marten::DB::Errors::RecordNotFound) { tag_qset.get!(name: "ruby") }
      expect_raises(Marten::DB::Errors::RecordNotFound) { tag_qset.get!(name: "crystal", is_active: false) }

      expect_raises(Marten::DB::Errors::RecordNotFound) { user_qset.get!(username: "foo") }
      expect_raises(Marten::DB::Errors::RecordNotFound) { user_qset.get!(username: "jd1", first_name: "Foo") }
    end

    it "raises if predicates expressed as q expressions does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      expect_raises(Marten::DB::Errors::RecordNotFound) { tag_qset.get! { q(name: "ruby") } }
      expect_raises(Marten::DB::Errors::RecordNotFound) { tag_qset.get! { q(name: "crystal") & q(is_active: false) } }

      expect_raises(Marten::DB::Errors::RecordNotFound) { user_qset.get! { q(username: "foo") } }
      expect_raises(Marten::DB::Errors::RecordNotFound) { user_qset.get! { q(username: "jd1") & q(first_name: "Foo") } }
    end

    it "raises if predicates expressed as query node objects does not match anything" do
      Tag.create!(name: "crystal", is_active: true)
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

      tag_qset = Marten::DB::Query::Set(Tag).new
      user_qset = Marten::DB::Query::Set(TestUser).new

      expect_raises(Marten::DB::Errors::RecordNotFound) { tag_qset.get!(Marten::DB::Query::Node.new(name: "ruby")) }
      expect_raises(Marten::DB::Errors::RecordNotFound) do
        tag_qset.get!(Marten::DB::Query::Node.new(name: "crystal", is_active: false))
      end

      expect_raises(Marten::DB::Errors::RecordNotFound) { user_qset.get!(Marten::DB::Query::Node.new(username: "foo")) }
      expect_raises(Marten::DB::Errors::RecordNotFound) do
        user_qset.get!(Marten::DB::Query::Node.new(username: "jd1", first_name: "Foo"))
      end
    end

    it "raises if multiple records are found when using predicates expressed as keyword arguments" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        qset.get!(name__startswith: "c")
      end
    end

    it "raises if multiple records are found when using predicates expressed as q expressions" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        qset.get! { q(name__startswith: "c") & q(is_active: true) }
      end
    end

    it "raises if multiple records are found when using predicates expressed as query node objects" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        qset.get!(Marten::DB::Query::Node.new(name__startswith: "c"))
      end
    end
  end

  describe "#get_or_create" do
    it "returns the record matched by the specified arguments" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.get_or_create(name: "crystal").should eq tag
      qset.size.should eq 2
    end

    it "creates a record using the specified arguments if no record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      new_tag = qset.get_or_create(name: "newtag", is_active: true)
      new_tag.persisted?.should be_true

      qset.size.should eq 3
    end

    it "creates a record using the specified arguments and the specified block if no record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      new_tag = qset.get_or_create(name: "newtag") do |t|
        t.is_active = true
      end

      new_tag.persisted?.should be_true

      qset.size.should eq 3
    end

    it "initializes a record but does not save it if it is invalid when no other record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      new_tag = qset.get_or_create(name: "newtag")
      new_tag.valid?.should be_false
      new_tag.persisted?.should be_false

      qset.size.should eq 2
    end

    it "initializes a record but does not save it if it is invalid when no other record is found and a block is used" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      new_tag = qset.get_or_create(name: "newtag") do |r|
        r.is_active = nil
      end

      new_tag.valid?.should be_false
      new_tag.persisted?.should be_false

      qset.size.should eq 2
    end

    it "raises if multiple records are found when using predicates expressed as keyword arguments" do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd@example.com", first_name: "John", last_name: "Doe")

      qset = Marten::DB::Query::Set(TestUser).new

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        qset.get_or_create(email: "jd@example.com")
      end
    end
  end

  describe "#get_or_create!" do
    it "returns the record matched by the specified arguments" do
      tag = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.get_or_create!(name: "crystal").should eq tag
      qset.size.should eq 2
    end

    it "creates a record using the specified arguments if no record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      new_tag = qset.get_or_create!(name: "newtag", is_active: true)
      new_tag.persisted?.should be_true

      qset.size.should eq 3
    end

    it "creates a record using the specified arguments and the specified block if no record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      new_tag = qset.get_or_create!(name: "newtag") do |t|
        t.is_active = true
      end

      new_tag.persisted?.should be_true

      qset.size.should eq 3
    end

    it "raises if the new record is invalid when no other record is found" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      expect_raises(Marten::DB::Errors::InvalidRecord) do
        qset.get_or_create!(name: "newtag")
      end

      qset.size.should eq 2
    end

    it "raises if the new record is invalid when no other record is found and a block is used" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      expect_raises(Marten::DB::Errors::InvalidRecord) do
        qset.get_or_create!(name: "newtag") do |r|
          r.is_active = nil
        end
      end

      qset.size.should eq 2
    end

    it "raises if multiple records are found when using predicates expressed as keyword arguments" do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd@example.com", first_name: "John", last_name: "Doe")

      qset = Marten::DB::Query::Set(TestUser).new

      expect_raises(Marten::DB::Errors::MultipleRecordsFound) do
        qset.get_or_create!(email: "jd@example.com")
      end
    end
  end

  describe "#includes?" do
    it "returns true if the passed record is present in the query set" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Marten::DB::Query::Set(Tag).new.includes?(tag_2).should be_true
    end

    it "returns true if the passed record is present in a query set that was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new
      qset.each { }

      qset.includes?(tag_2).should be_true
    end

    it "returns false if the passed record is not present in the query set" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: false)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      Marten::DB::Query::Set(Tag).new.filter(is_active: true).includes?(tag_2).should be_false
    end

    it "returns false if the passed record is not present in a query set that was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: false)
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.filter(is_active: true)
      qset.each { }

      qset.includes?(tag_2).should be_false
    end

    it "raises if the passed record is not persisted" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "#{tag} is not persisted") do
        Marten::DB::Query::Set(Tag).new.includes?(tag)
      end
    end
  end

  describe "#inspect" do
    it "produces the expected output for an empty queryset" do
      Marten::DB::Query::Set(Tag).new.inspect.should eq "<Marten::DB::Query::Set(Tag) []>"
    end

    it "produces the expected output for a queryset with a small number of records" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new
      qset.each { }

      qset.inspect.should eq(
        "<Marten::DB::Query::Set(Tag) [" \
        "#<Tag:0x#{qset[0].object_id.to_s(16)} id: 1, name: \"crystal\", is_active: true>, " \
        "#<Tag:0x#{qset[1].object_id.to_s(16)} id: 2, name: \"coding\", is_active: true>" \
        "]>"
      )
    end

    it "produces the expected output for a queryset with a large number of records" do
      30.times do |i|
        Tag.create!(name: "tag-#{i}", is_active: true)
      end

      qset = Marten::DB::Query::Set(Tag).new
      qset.inspect.ends_with?(", ...(remaining truncated)...]>").should be_true
    end
  end

  describe "#join" do
    it "allows to specify relations to join as strings" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")

      qset = Marten::DB::Query::Set(Post).new.order(:id)
      qset = qset.join("author")

      qset[0].__set_spec_author.should eq user_1
      qset[1].__set_spec_author.should eq user_2
    end

    it "allows to specify relations to join as symbols" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2")

      qset = Marten::DB::Query::Set(Post).new.order(:id)
      qset = qset.join(:author)

      qset[0].__set_spec_author.should eq user_1
      qset[1].__set_spec_author.should eq user_2
    end

    it "allows to specify multiple relations to join" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1")
      Post.create!(author: user_2, title: "Post 2", updated_by: user_1)

      qset = Marten::DB::Query::Set(Post).new.order(:id)
      qset = qset.join(:author, :updated_by)

      qset[0].__set_spec_author.should eq user_1
      qset[0].__set_spec_updated_by.should be_nil

      qset[1].__set_spec_author.should eq user_2
      qset[1].__set_spec_updated_by.should eq user_1
    end

    it "allows to specify one-to-one reverse relations" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_profile_1 = TestUserProfile.create!(user: user_1)
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      qset = Marten::DB::Query::Set(TestUser).new.order(:id)
      qset = qset.join(:profile)

      qset[0].should eq user_1
      qset[0].__set_spec_profile.should eq user_profile_1

      qset[1].should eq user_2
      qset[1].__set_spec_profile.should be_nil
    end

    it "raises if the specified relation is not a single record relation" do
      expect_raises(Marten::DB::Errors::InvalidField, /Unable to resolve 'tags' as a relation field/) do
        Marten::DB::Query::Set(Post).new.join(:tags)
      end
    end

    it "raises if the specified reverse relation is not a single record relation" do
      expect_raises(Marten::DB::Errors::InvalidField, /Unable to resolve 'posts' as a relation field/) do
        Marten::DB::Query::Set(TestUser).new.join(:posts)
      end
    end

    it "raises as expected when called without arguments" do
      qset = Marten::DB::Query::Set(Post).new

      expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Relations must be specified when joining") do
        qset.join
      end
    end

    context "with multi table inheritance" do
      it "allows to specify direct one-to-one reverse relations" do
        address = Marten::DB::Query::SetSpec::Address.create!(street: "Street 2")
        student = Marten::DB::Query::SetSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        Marten::DB::Query::SetSpec::PersonProfile.create!(person: student)
        student_profile = Marten::DB::Query::SetSpec::StudentProfile.create!(student: student)

        qset = Marten::DB::Query::Set(Marten::DB::Query::SetSpec::Student).new.order(:id)
        qset = qset.join(:student_profile)

        qset[0].should eq student
        qset[0].__set_spec_student_profile.should eq student_profile
      end

      it "allows to specify inherited one-to-one reverse relations" do
        address = Marten::DB::Query::SetSpec::Address.create!(street: "Street 2")
        student = Marten::DB::Query::SetSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        person_profile = Marten::DB::Query::SetSpec::PersonProfile.create!(person: student)
        Marten::DB::Query::SetSpec::StudentProfile.create!(student: student)

        qset = Marten::DB::Query::Set(Marten::DB::Query::SetSpec::Student).new
        qset = qset.join(:person_profile)

        qset[0].should eq student
        qset[0].__set_spec_person_profile.should eq person_profile
      end

      it "allows to specify both direct and inherited one-to-one reverse relations at the same time" do
        address = Marten::DB::Query::SetSpec::Address.create!(street: "Street 2")
        student = Marten::DB::Query::SetSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        person_profile = Marten::DB::Query::SetSpec::PersonProfile.create!(person: student)
        student_profile = Marten::DB::Query::SetSpec::StudentProfile.create!(student: student)

        qset_1 = Marten::DB::Query::Set(Marten::DB::Query::SetSpec::Student).new
        qset_1 = qset_1.join(:person_profile, :student_profile)

        qset_1[0].should eq student
        qset_1[0].__set_spec_person_profile.should eq person_profile
        qset_1[0].__set_spec_student_profile.should eq student_profile

        qset_2 = Marten::DB::Query::Set(Marten::DB::Query::SetSpec::Student).new
        qset_2 = qset_2.join(:student_profile, :person_profile)

        qset_2[0].should eq student
        qset_2[0].__set_spec_person_profile.should eq person_profile
        qset_2[0].__set_spec_student_profile.should eq student_profile
      end
    end
  end

  describe "#last" do
    it "returns the last result for an ordered queryset" do
      Tag.create!(name: "crystal", is_active: true)
      tag_2 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:name)

      qset.last.should eq tag_2
    end

    it "returns the last result ordered according to primary keys for an unordered queryset" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.last.should eq tag_3
    end

    it "returns nil if the queryset doesn't match any records" do
      qset = Marten::DB::Query::Set(Tag).new
      qset.last.should be_nil
    end
  end

  describe "#last!" do
    it "returns the last result for an ordered queryset" do
      Tag.create!(name: "crystal", is_active: true)
      tag_2 = Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new.order(:name)

      qset.last!.should eq tag_2
    end

    it "returns the last result ordered according to primary keys for an unordered queryset" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.last!.should eq tag_3
    end

    it "raises a NilAssertionError error if the queryset doesn't match any records" do
      qset = Marten::DB::Query::Set(Tag).new
      expect_raises(NilAssertionError) { qset.last!.should be_nil }
    end
  end

  describe "#model" do
    it "returns the associated model" do
      Marten::DB::Query::Set(Tag).new.model.should eq Tag
      Marten::DB::Query::Set(Post).new.model.should eq Post
    end
  end

  describe "#none" do
    it "returns an empty queryset" do
      Tag.create!(name: "coding", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "typing", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.none.query.should be_a Marten::DB::Query::SQL::EmptyQuery(Tag)
      qset.none.exists?.should be_false
      qset.none.size.should eq 0
      qset.none.should be_empty
    end
  end

  describe "#order" do
    it "allows to order using a specific column specified as a string" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.order("name").to_a.should eq [tag_2, tag_3, tag_1]
      qset.order("-name").to_a.should eq [tag_1, tag_3, tag_2]
    end

    it "allows to order using a specific column specified as a symbol" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.order(:name).to_a.should eq [tag_2, tag_3, tag_1]
      qset.order(:"-name").to_a.should eq [tag_1, tag_3, tag_2]
    end

    it "allows to order using multiple columns" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      qset = Marten::DB::Query::Set(TestUser).new

      qset.order(:first_name, :last_name).to_a.should eq [user_3, user_2, user_1]
    end

    it "allows to order from an array of strings" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      qset = Marten::DB::Query::Set(TestUser).new

      qset.order(["first_name", "last_name"]).to_a.should eq [user_3, user_2, user_1]
    end

    it "allows to order from an array of symbols" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      qset = Marten::DB::Query::Set(TestUser).new

      qset.order([:first_name, :last_name]).to_a.should eq [user_3, user_2, user_1]
    end
  end

  describe "#paginator" do
    it "returns a paginator for the query set" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      qset = Marten::DB::Query::Set(TestUser).new.order(:username)
      qset.paginator(2).should be_a Marten::DB::Query::Paginator(TestUser)
      qset.paginator(2).page(1).size.should eq 2
      qset.paginator(2).page(1).to_a.should eq [user_1, user_3]
    end
  end

  describe "#pick" do
    context "with double splat arguments" do
      it "allows extracting a specific field value whose name is expressed as a symbol" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick(:username).should eq ["jd1"]
      end

      it "allows extracting a specific field value whose name is expressed as a string" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick("username").should eq ["jd1"]
      end

      it "allows extracting multiple specific fields values" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick(:first_name, :last_name).should eq ["John", "Doe"]
      end

      it "allows extracting specific fields by following associations" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        post = Post.create!(author: test_user, title: "Post 1", published: true)

        Post.filter(pk: post.pk).pick(:title, :author__first_name).should eq ["Post 1", "John"]
      end

      it "returns nil if the queryset does not match any record" do
        TestUser.filter(pk: -1).pick(:username).should be_nil
      end
    end

    context "with array of field names" do
      it "allows extracting a specific field value whose name is expressed as a symbol" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick([:username]).should eq ["jd1"]
      end

      it "allows extracting a specific field value whose name is expressed as a string" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick(["username"]).should eq ["jd1"]
      end

      it "allows extracting multiple specific fields values" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick([:first_name, :last_name]).should eq ["John", "Doe"]
      end

      it "allows extracting specific fields by following associations" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        post = Post.create!(author: test_user, title: "Post 1", published: true)

        Post.filter(pk: post.pk).pick([:title, :author__first_name]).should eq ["Post 1", "John"]
      end

      it "returns nil if the queryset does not match any record" do
        TestUser.filter(pk: -1).pick([:username]).should be_nil
      end
    end
  end

  describe "#pick!" do
    context "with double splat arguments" do
      it "allows extracting a specific field value whose name is expressed as a symbol" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick!(:username).should eq ["jd1"]
      end

      it "allows extracting a specific field value whose name is expressed as a string" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick!("username").should eq ["jd1"]
      end

      it "allows extracting multiple specific fields values" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick!(:first_name, :last_name).should eq ["John", "Doe"]
      end

      it "allows extracting specific fields by following associations" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        post = Post.create!(author: test_user, title: "Post 1", published: true)

        Post.filter(pk: post.pk).pick!(:title, :author__first_name).should eq ["Post 1", "John"]
      end

      it "raises NilAssertionError if the queryset does not match any record" do
        expect_raises(NilAssertionError) do
          TestUser.filter(pk: -1).pick!(:username)
        end
      end
    end

    context "with array of field names" do
      it "allows extracting a specific field value whose name is expressed as a symbol" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick!([:username]).should eq ["jd1"]
      end

      it "allows extracting a specific field value whose name is expressed as a string" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick!(["username"]).should eq ["jd1"]
      end

      it "allows extracting multiple specific fields values" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")

        TestUser.filter(pk: test_user.pk).pick!([:first_name, :last_name]).should eq ["John", "Doe"]
      end

      it "allows extracting specific fields by following associations" do
        test_user = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        post = Post.create!(author: test_user, title: "Post 1", published: true)

        Post.filter(pk: post.pk).pick!([:title, :author__first_name]).should eq ["Post 1", "John"]
      end

      it "raises NilAssertionError if the queryset does not match any record" do
        expect_raises(NilAssertionError) do
          TestUser.filter(pk: -1).pick!([:username])
        end
      end
    end
  end

  describe "#pks" do
    it "extracts the primary keys of the records matched by the considered query set" do
      test_user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      test_user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      test_user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

      TestUser.all.pks.should eq [test_user_1.pk, test_user_2.pk, test_user_3.pk]
      TestUser.filter { q(username: "jd1") | q(username: "jd2") }.pks.should eq [test_user_1.pk, test_user_2.pk]
    end
  end

  describe "#pluck" do
    context "with double splat arguments" do
      it "allows extracting a specific field value whose name is expressed as a symbol" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.all.pluck(:username).should eq [["jd1"], ["jd2"], ["jd3"]]
      end

      it "allows extracting a specific field value whose name is expressed as a string" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.all.pluck("username").should eq [["jd1"], ["jd2"], ["jd3"]]
      end

      it "allows extracting multiple specific fields values" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.all.pluck(:first_name, :last_name).should eq [["John", "Doe"], ["John", "Doe"], ["Bob", "Doe"]]
      end

      it "allows extracting specific fields by following associations" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        Post.create!(author: user_1, title: "Post 1", published: true)
        Post.create!(author: user_1, title: "Post 2", published: true)
        Post.create!(author: user_2, title: "Post 3", published: true)
        Post.create!(author: user_1, title: "Post 4", published: false)
        Post.create!(author: user_3, title: "Post 5", published: false)

        Post.all.pluck(:title, :author__first_name).to_set.should eq(
          [["Post 1", "John"], ["Post 2", "John"], ["Post 3", "John"], ["Post 4", "John"], ["Post 5", "Bob"]].to_set
        )
      end
    end

    context "with array of field names" do
      it "allows extracting a specific field value whose name is expressed as a symbol" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.all.pluck([:username]).should eq [["jd1"], ["jd2"], ["jd3"]]
      end

      it "allows extracting a specific field value whose name is expressed as a string" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.all.pluck(["username"]).should eq [["jd1"], ["jd2"], ["jd3"]]
      end

      it "allows extracting multiple specific fields values" do
        TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        TestUser.all.pluck([:first_name, :last_name]).should eq [["John", "Doe"], ["John", "Doe"], ["Bob", "Doe"]]
      end

      it "allows extracting specific fields by following associations" do
        user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
        user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
        user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "Bob", last_name: "Doe")

        Post.create!(author: user_1, title: "Post 1", published: true)
        Post.create!(author: user_1, title: "Post 2", published: true)
        Post.create!(author: user_2, title: "Post 3", published: true)
        Post.create!(author: user_1, title: "Post 4", published: false)
        Post.create!(author: user_3, title: "Post 5", published: false)

        Post.all.pluck([:title, :author__first_name]).to_set.should eq(
          [["Post 1", "John"], ["Post 2", "John"], ["Post 3", "John"], ["Post 4", "John"], ["Post 5", "Bob"]].to_set
        )
      end
    end
  end

  describe "#product" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError) { Marten::DB::Query::Set(Tag).new.product }
    end
  end

  describe "#raw" do
    it "returns the expected records for non-parameterized queries" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.raw("select * from app_tag order by id;").to_a.should eq [tag_1, tag_2, tag_3]
      qset.raw("select * from app_tag where name = 'crystal';").to_a.should eq [tag_2]
    end

    it "returns the expected records for queries involving positional parameters" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.raw("select * from app_tag where name = ?;", ["crystal"]).to_a.should eq [tag_2]
      qset.raw("select * from app_tag where name = ? or name = ? order by id;", ["ruby", "coding"]).to_a.should eq(
        [tag_1, tag_3]
      )
    end

    it "returns the expected records for queries involving splat positional parameters" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.raw("select * from app_tag where name = ?;", "crystal").to_a.should eq [tag_2]
      qset.raw("select * from app_tag where name = ? or name = ? order by id;", "ruby", "coding").to_a.should eq(
        [tag_1, tag_3]
      )
    end

    it "returns the expected records for queries involving named parameters expressed as a named tuple" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.raw("select * from app_tag where name = :name;", {name: "crystal"}).to_a.should eq [tag_2]
      qset.raw(
        "select * from app_tag where name = :name1 or name = :name2 order by id;",
        {name1: "ruby", name2: "coding"}
      ).to_a.should eq(
        [tag_1, tag_3]
      )
    end

    it "returns the expected records for queries involving named parameters expressed as a hash" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.raw("select * from app_tag where name = :name;", {"name" => "crystal"}).to_a.should eq [tag_2]
      qset.raw(
        "select * from app_tag where name = :name1 or name = :name2 order by id;",
        {"name1" => "ruby", "name2" => "coding"}
      ).to_a.should eq([tag_1, tag_3])
    end

    it "returns the expected records for queries involving double splat named parameters" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.raw("select * from app_tag where name = :name;", name: "crystal").to_a.should eq [tag_2]
      qset.raw(
        "select * from app_tag where name = :name1 or name = :name2 order by id;",
        name1: "ruby",
        name2: "coding"
      ).to_a.should eq([tag_1, tag_3])
    end
  end

  describe "#reverse" do
    it "reverses the current order of the considered queryset" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "programming", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.order(:name).reverse.to_a.should eq [tag_1, tag_3, tag_2]
    end
  end

  describe "#size" do
    it "returns the expected number of record for an unfiltered query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::Set(Tag).new.size.should eq 3
    end

    it "returns the expected number of record for a filtered query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      Marten::DB::Query::Set(Tag).new.filter(name__startswith: :c).size.should eq 2
      Marten::DB::Query::Set(Tag).new.filter(name__startswith: "r").size.should eq 1
      Marten::DB::Query::Set(Tag).new.filter(name__startswith: "x").size.should eq 0
    end
  end

  describe "#sum" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError) { Marten::DB::Query::Set(Tag).new.sum }
    end
  end

  describe "#to_h" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError) { Marten::DB::Query::Set(Tag).new.to_h }
    end
  end

  describe "#to_s" do
    it "produces the expected output for an empty queryset" do
      Marten::DB::Query::Set(Tag).new.to_s.should eq "<Marten::DB::Query::Set(Tag) []>"
    end

    it "produces the expected output for a queryset with a small number of records" do
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new
      qset.each { }

      qset.to_s.should eq(
        "<Marten::DB::Query::Set(Tag) [" \
        "#<Tag:0x#{qset[0].object_id.to_s(16)} id: 1, name: \"crystal\", is_active: true>, " \
        "#<Tag:0x#{qset[1].object_id.to_s(16)} id: 2, name: \"coding\", is_active: true>" \
        "]>"
      )
    end

    it "produces the expected output for a queryset with a large number of records" do
      30.times do |i|
        Tag.create!(name: "tag-#{i}", is_active: true)
      end

      qset = Marten::DB::Query::Set(Tag).new
      qset.to_s.ends_with?(", ...(remaining truncated)...]>").should be_true
    end
  end

  describe "#update" do
    it "allows to update the records matching a given queryset with values specified as keyword arguments" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      qset = Marten::DB::Query::Set(TestUser).new

      qset.filter(first_name: "John").update(last_name: "Updated", is_admin: true).should eq 2

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

    it "allows to update the records matching a given queryset with values specified as a hash" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      qset = Marten::DB::Query::Set(TestUser).new

      qset.filter(first_name: "John").update({"last_name" => "Updated", "is_admin" => true}).should eq 2

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

    it "allows to update the records matching a given queryset with values specified as a named tuple" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      qset = Marten::DB::Query::Set(TestUser).new

      qset.filter(first_name: "John").update({last_name: "Updated", is_admin: true}).should eq 2

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

    it "returns 0 if no rows were affected by the updated" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      user_3 = TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      qset = Marten::DB::Query::Set(TestUser).new

      qset.filter(first_name: "Unknown").update({last_name: "Updated", is_admin: true}).should eq 0

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

    it "resets cached records" do
      user_1 = TestUser.create!(username: "abc", email: "abc@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "ghi", email: "ghi@example.com", first_name: "John", last_name: "Bar")
      TestUser.create!(username: "def", email: "def@example.com", first_name: "Bob", last_name: "Abc")

      qset = Marten::DB::Query::Set(TestUser).new.filter(first_name: "John")

      qset.to_set.should eq(Set{user_1, user_2})

      qset.update(first_name: "Updated", is_admin: true).should eq 2

      qset.to_a.should be_empty
    end
  end

  describe "#using" do
    it "allows to switch to another DB connection" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.using(:other).create!(name: "coding", is_active: true)
      tag_3 = Tag.using(:other).create!(name: "crystal", is_active: true)

      qset = Marten::DB::Query::Set(Tag).new

      qset.to_a.should eq [tag_1]
      qset.using(:other).to_a.should eq [tag_2, tag_3]
    end
  end
end

class Post
  def __set_spec_author
    @author
  end

  def __set_spec_updated_by
    @updated_by
  end
end

class TestUser
  def __set_spec_profile
    @_reverse_o2o_profile
  end
end
