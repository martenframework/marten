require "./spec_helper"

describe Marten::DB::Query::SQL::RawQuery do
  describe "#clone" do
    it "results in a new raw query object when using the default connection" do
      raw_query = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from tags where name = ?",
        params: ["crystal"] of DB::Any,
        using: nil
      )

      cloned = raw_query.clone

      cloned.object_id.should_not eq raw_query.object_id
      cloned.query.should eq "select * from tags where name = ?"
      cloned.params.should eq ["crystal"]
      cloned.using.should be_nil
    end

    it "results in a new raw query object when using a custom connection" do
      raw_query = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from tags where name = ?",
        params: ["crystal"] of DB::Any,
        using: "other"
      )

      cloned = raw_query.clone

      cloned.object_id.should_not eq raw_query.object_id
      cloned.query.should eq "select * from tags where name = ?"
      cloned.params.should eq ["crystal"]
      cloned.using.should eq "other"
    end
  end

  describe "#connection" do
    it "returns the model connection by default" do
      raw_query = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from tags where name = ?",
        params: ["crystal"] of DB::Any,
        using: nil
      )

      raw_query.connection.should eq Tag.connection
    end

    it "returns the specified connection if applicable" do
      raw_query = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from tags where name = ?",
        params: ["crystal"] of DB::Any,
        using: "other"
      )

      raw_query.connection.should eq Marten::DB::Connection.get("other")
    end
  end

  describe "#execute" do
    it "returns the expected records for a non-parameterized query" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      raw_query_1 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag;",
        params: [] of DB::Any,
        using: nil
      )
      raw_query_1.execute.to_set.should eq [tag_1, tag_2, tag_3].to_set

      raw_query_2 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = 'crystal';",
        params: [] of DB::Any,
        using: nil
      )
      raw_query_2.execute.should eq [tag_2]
    end

    it "returns the expected records for a non-parameterized query targetting a specific DB connection" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.using(:other).create!(name: "crystal", is_active: true)
      tag_3 = Tag.using(:other).create!(name: "coding", is_active: true)

      raw_query_1 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag;",
        params: [] of DB::Any,
        using: "other"
      )
      raw_query_1.execute.to_set.should eq [tag_2, tag_3].to_set

      raw_query_2 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = 'crystal';",
        params: [] of DB::Any,
        using: "other"
      )
      raw_query_2.execute.should eq [tag_2]
    end

    it "returns the expected records for queries involving positional parameters" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      raw_query_1 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["crystal"] of DB::Any,
        using: nil
      )
      raw_query_1.execute.should eq [tag_2]

      raw_query_2 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = ? or name = ?;",
        params: ["ruby", "coding"] of DB::Any,
        using: nil
      )
      raw_query_2.execute.to_set.should eq [tag_1, tag_3].to_set
    end

    it "returns the expected records for queries involving positional parameters and a specific DB connection" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.using(:other).create!(name: "crystal", is_active: true)
      tag_3 = Tag.using(:other).create!(name: "coding", is_active: true)

      raw_query_1 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: ["crystal"] of DB::Any,
        using: "other"
      )
      raw_query_1.execute.should eq [tag_2]

      raw_query_2 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = ? or name = ?;",
        params: ["ruby", "coding"] of DB::Any,
        using: "other"
      )
      raw_query_2.execute.should eq [tag_3]
    end

    it "raises if the number of positional parameters in the query does not match the number of parameter values" do
      raw_query_1 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = ? or name = ?;",
        params: ["crystal"] of DB::Any,
        using: "other"
      )
      expect_raises(
        Marten::DB::Errors::UnmetQuerySetCondition,
        "Wrong number of parameters provided for query: select * from app_tag where name = ? or name = ?"
      ) do
        raw_query_1.execute
      end

      raw_query_2 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = ?;",
        params: [] of DB::Any,
        using: "other"
      )
      expect_raises(
        Marten::DB::Errors::UnmetQuerySetCondition,
        "Wrong number of parameters provided for query: select * from app_tag where name = ?"
      ) do
        raw_query_2.execute
      end
    end

    it "returns the expected records for queries involving named parameters" do
      tag_1 = Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "coding", is_active: true)

      raw_query_1 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = :name;",
        params: {"name" => "crystal"} of String => DB::Any,
        using: nil
      )
      raw_query_1.execute.should eq [tag_2]

      raw_query_2 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = :name1 or name = :name2;",
        params: {"name1" => "ruby", "name2" => "coding"} of String => DB::Any,
        using: nil
      )
      raw_query_2.execute.to_set.should eq [tag_1, tag_3].to_set
    end

    it "returns the expected records for queries involving named parameters and a specific DB connection" do
      Tag.create!(name: "ruby", is_active: true)
      tag_2 = Tag.using(:other).create!(name: "crystal", is_active: true)
      tag_3 = Tag.using(:other).create!(name: "coding", is_active: true)

      raw_query_1 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = :name;",
        params: {"name" => "crystal"} of String => DB::Any,
        using: "other"
      )
      raw_query_1.execute.should eq [tag_2]

      raw_query_2 = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = :name1 or name = :name2;",
        params: {"name1" => "ruby", "name2" => "coding"} of String => DB::Any,
        using: "other"
      )
      raw_query_2.execute.should eq [tag_3]
    end

    it "raises if some named parameters in the query were not specified in the parameter values" do
      raw_query = Marten::DB::Query::SQL::RawQuery(Tag).new(
        query: "select * from app_tag where name = :name;",
        params: {"dummy" => "crystal"} of String => DB::Any,
        using: "other"
      )
      expect_raises(
        Marten::DB::Errors::UnmetQuerySetCondition,
        "Missing parameter 'name' for query: select * from app_tag where name = :name"
      ) do
        raw_query.execute
      end
    end

    for_postgresql do
      it "properly handles the cast syntax" do
        Tag.create!(name: "ruby", is_active: false)
        tag_2 = Tag.create!(name: "crystal", is_active: true)
        tag_3 = Tag.create!(name: "coding", is_active: true)

        raw_query = Marten::DB::Query::SQL::RawQuery(Tag).new(
          query: "select * from app_tag where is_active::integer = :is_active",
          params: {"is_active" => 1} of String => DB::Any,
          using: nil
        )
        raw_query.execute.to_set.should eq [tag_2, tag_3].to_set
      end
    end
  end
end
