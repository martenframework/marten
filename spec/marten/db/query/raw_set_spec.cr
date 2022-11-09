require "./spec_helper"

describe Marten::DB::Query::RawSet do
  describe "#[]" do
    context "with an index" do
      it "returns the expected record for a given index when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        Tag.create!(name: "ruby", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[1].should eq tag_2
      end

      it "returns the expected record for a given index when the query set already fetched the records" do
        tag_1 = Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[0].should eq tag_1
        qset[1].should eq tag_2
        qset[2].should eq tag_3
        qset[3].should eq tag_4
      end

      it "raises if the specified index is negative" do
        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
          qset[-1]
        end
      end

      it "raises an IndexError when the index is out of bound when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        Tag.create!(name: "crystal", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        expect_raises(IndexError) do
          qset[20]
        end
      end

      it "raises an IndexError the index is out of bound when the query set already fetched the records" do
        Tag.create!(name: "coding", is_active: true)
        Tag.create!(name: "crystal", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        expect_raises(IndexError) do
          qset[20]
        end
      end
    end

    context "with a range" do
      it "returns the expected records for a given range when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[1..3].to_a.should eq [tag_2, tag_3, tag_4]
      end

      it "returns the expected records for a given range when the query set already fetched the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[1..3].should eq [tag_2, tag_3, tag_4]
      end

      it "returns the expected records for an exclusive range when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[1...3].to_a.should eq [tag_2, tag_3]
      end

      it "returns the expected records for an exclusive range when the query set already fetched the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[1...3].should eq [tag_2, tag_3]
      end

      it "returns the expected records for a begin-less range when the query set didn't already fetch the records" do
        tag_1 = Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[..3].to_a.should eq [tag_1, tag_2, tag_3, tag_4]
      end

      it "returns the expected records for a begin-less range when the query set already fetched the records" do
        tag_1 = Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[..3].should eq [tag_1, tag_2, tag_3, tag_4]
      end

      it "returns the expected records for an end-less range when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        tag_5 = Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[2..].to_a.should eq [tag_3, tag_4, tag_5]
      end

      it "returns the expected records for an end-less range when the query set already fetched the records" do
        Tag.create!(name: "coding", is_active: true)
        Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        tag_5 = Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[2..].to_a.should eq [tag_3, tag_4, tag_5]
      end

      it "raises if the specified range has a negative beginning" do
        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
          qset[-1..10]
        end
      end

      it "raises if the specified range has a negative end" do
        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
          qset[10..-1]
        end
      end
    end
  end

  describe "#[]?" do
    context "with an index" do
      it "returns the expected record for a given index when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        Tag.create!(name: "ruby", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[1]?.should eq tag_2
      end

      it "returns the expected record for a given index when the query set already fetched the records" do
        tag_1 = Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[0]?.should eq tag_1
        qset[1]?.should eq tag_2
        qset[2]?.should eq tag_3
        qset[3]?.should eq tag_4
      end

      it "raises if the specified index is negative" do
        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
          qset[-1]?
        end
      end

      it "returns nil if the specified index is out of bound when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        Tag.create!(name: "crystal", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[20]?.should be_nil
      end

      it "returns nil the specified index is out of bound when the query set already fetched the records" do
        Tag.create!(name: "coding", is_active: true)
        Tag.create!(name: "crystal", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[20]?.should be_nil
      end
    end

    context "with a range" do
      it "returns the expected records for a given range when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[1..3]?.not_nil!.to_a.should eq [tag_2, tag_3, tag_4]
      end

      it "returns the expected records for a given range when the query set already fetched the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[1..3]?.should eq [tag_2, tag_3, tag_4]
      end

      it "returns the expected records for a begin-less range when the query set didn't already fetch the records" do
        tag_1 = Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[..3]?.not_nil!.to_a.should eq [tag_1, tag_2, tag_3, tag_4]
      end

      it "returns the expected records for an exclusive range when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[1...3]?.not_nil!.to_a.should eq [tag_2, tag_3]
      end

      it "returns the expected records for an exclusive range when the query set already fetched the records" do
        Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[1...3]?.not_nil!.should eq [tag_2, tag_3]
      end

      it "returns the expected records for a begin-less range when the query set already fetched the records" do
        tag_1 = Tag.create!(name: "coding", is_active: true)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[..3]?.not_nil!.should eq [tag_1, tag_2, tag_3, tag_4]
      end

      it "returns the expected records for an end-less range when the query set didn't already fetch the records" do
        Tag.create!(name: "coding", is_active: true)
        Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        tag_5 = Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        qset[2..]?.not_nil!.to_a.should eq [tag_3, tag_4, tag_5]
      end

      it "returns the expected records for an end-less range when the query set already fetched the records" do
        Tag.create!(name: "coding", is_active: true)
        Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "ruby", is_active: true)
        tag_4 = Tag.create!(name: "programming", is_active: true)
        tag_5 = Tag.create!(name: "typing", is_active: true)

        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )
        qset.each { }

        qset[2..]?.not_nil!.to_a.should eq [tag_3, tag_4, tag_5]
      end

      it "raises if the specified range has a negative beginning" do
        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
          qset[-1..10]?
        end
      end

      it "raises if the specified range has a negative end" do
        qset = Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        )

        expect_raises(Marten::DB::Errors::UnmetQuerySetCondition, "Negative indexes are not supported") do
          qset[10..-1]?
        end
      end
    end
  end

  describe "#accumulate" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError) do
        Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        ).accumulate
      end
    end
  end

  describe "#count" do
    it "returns the expected number of record for a non-parameterized query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag order by id",
        params: [] of DB::Any,
        using: nil
      )

      qset.count.should eq 3
    end

    it "returns the expected number of record for a non-parameterized query set that was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag order by id",
        params: [] of DB::Any,
        using: nil
      )
      qset.each { }

      qset.count.should eq 3
    end

    it "returns the expected number of record for a parameterized query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["crystal"] of DB::Any,
        using: nil
      )
      qset_1.count.should eq 1

      qset_2 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["unknown"] of DB::Any,
        using: nil
      )
      qset_2.count.should eq 0

      qset_3 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name1 or name = :name2;",
        params: {"name1" => "ruby", "name2" => "coding"} of String => DB::Any,
        using: nil
      )
      qset_3.count.should eq 2

      qset_4 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name;",
        params: {"name" => "unknown"} of String => DB::Any,
        using: nil
      )
      qset_4.count.should eq 0
    end

    it "returns the expected number of record for a filtered query set that was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["crystal"] of DB::Any,
        using: nil
      )
      qset_1.each { }
      qset_1.count.should eq 1

      qset_2 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["unknown"] of DB::Any,
        using: nil
      )
      qset_2.each { }
      qset_2.count.should eq 0

      qset_3 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name1 or name = :name2;",
        params: {"name1" => "ruby", "name2" => "coding"} of String => DB::Any,
        using: nil
      )
      qset_3.each { }
      qset_3.count.should eq 2

      qset_4 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name;",
        params: {"name" => "unknown"} of String => DB::Any,
        using: nil
      )
      qset_4.each { }
      qset_4.count.should eq 0
    end
  end

  describe "#each" do
    it "allows to iterate over the records targetted by the query set if it wasn't already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      tags = [] of Tag

      qset = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name1 or name = :name2 order by id;",
        params: {"name1" => "crystal", "name2" => "coding"} of String => DB::Any,
        using: nil
      )
      qset.each do |t|
        tags << t
      end

      tags.should eq [tag_2, tag_3]
    end

    it "allows to iterate over the records targetted by the query set if it was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      tags = [] of Tag

      qset = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name1 or name = :name2 order by id;",
        params: {"name1" => "crystal", "name2" => "coding"} of String => DB::Any,
        using: nil
      )
      qset.each { }

      qset.each do |t|
        tags << t
      end

      tags.should eq [tag_2, tag_3]
    end
  end

  describe "#product" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError) do
        Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        ).product
      end
    end
  end

  describe "#size" do
    it "returns the expected number of record for a non-parameterized query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag order by id",
        params: [] of DB::Any,
        using: nil
      )

      qset.size.should eq 3
    end

    it "returns the expected number of record for a non-parameterized query set that was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag order by id",
        params: [] of DB::Any,
        using: nil
      )
      qset.each { }

      qset.size.should eq 3
    end

    it "returns the expected number of record for a parameterized query set" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["crystal"] of DB::Any,
        using: nil
      )
      qset_1.size.should eq 1

      qset_2 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["unknown"] of DB::Any,
        using: nil
      )
      qset_2.size.should eq 0

      qset_3 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name1 or name = :name2;",
        params: {"name1" => "ruby", "name2" => "coding"} of String => DB::Any,
        using: nil
      )
      qset_3.size.should eq 2

      qset_4 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name;",
        params: {"name" => "unknown"} of String => DB::Any,
        using: nil
      )
      qset_4.size.should eq 0
    end

    it "returns the expected number of record for a filtered query set that was already fetched" do
      Tag.create!(name: "ruby", is_active: true)
      Tag.create!(name: "crystal", is_active: true)
      Tag.create!(name: "coding", is_active: true)

      qset_1 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["crystal"] of DB::Any,
        using: nil
      )
      qset_1.each { }
      qset_1.size.should eq 1

      qset_2 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["unknown"] of DB::Any,
        using: nil
      )
      qset_2.each { }
      qset_2.size.should eq 0

      qset_3 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name1 or name = :name2;",
        params: {"name1" => "ruby", "name2" => "coding"} of String => DB::Any,
        using: nil
      )
      qset_3.each { }
      qset_3.size.should eq 2

      qset_4 = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag where name = :name;",
        params: {"name" => "unknown"} of String => DB::Any,
        using: nil
      )
      qset_4.each { }
      qset_4.size.should eq 0
    end
  end

  describe "#sum" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError) do
        Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        ).sum
      end
    end
  end

  describe "#to_h" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError) do
        Marten::DB::Query::RawSet(Tag).new(
          query: "select * from app_tag order by id",
          params: [] of DB::Any,
          using: nil
        ).to_h
      end
    end
  end

  describe "#using" do
    it "allows to switch to another DB connection" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.using(:other).create!(name: "coding", is_active: true)
      tag_3 = Tag.using(:other).create!(name: "crystal", is_active: true)

      qset = Marten::DB::Query::RawSet(Tag).new(
        query: "select * from app_tag order by id",
        params: [] of DB::Any,
        using: nil
      )

      qset.to_a.should eq [tag_1]
      qset.using(:other).to_a.should eq [tag_2, tag_3]
    end
  end
end
