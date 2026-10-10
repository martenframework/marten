require "./spec_helper"

describe Marten::DB::Model::Connection do
  describe "::connection" do
    it "returns the default connection to use for the considered model" do
      TestUser.connection.should eq Marten::DB::Connection.default
    end

    it "returns the connection suggested by routers" do
      with_overridden_setting(
        :database_routers,
        [Marten::DB::Model::ConnectionSpec::OtherDBRouter] of Marten::DB::Router::Base.class
      ) do
        TestUser.connection.should eq Marten::DB::Connection.get("other")
      end
    end

    it "returns the write connection suggested by routers" do
      with_overridden_setting(
        :database_routers,
        [Marten::DB::Model::ConnectionSpec::PrimaryReplicaRouter] of Marten::DB::Router::Base.class
      ) do
        TestUser.connection.should eq Marten::DB::Connection.get("other")
        TestUser.connection(write: true).should eq Marten::DB::Connection.default
      end
    end
  end

  describe "#using" do
    it "is nil by default" do
      Tag.new(name: "coding", is_active: true).using.should be_nil
    end

    it "is set when a record is loaded from a non-default database" do
      tag = Tag.using(:other).create!(name: "coding", is_active: true)

      tag.using.should eq "other"
      Tag.using(:other).get!(pk: tag.pk).using.should eq "other"
    end

    it "is used for subsequent bare saves" do
      tag = Tag.using(:other).create!(name: "coding", is_active: true)
      tag.name = "crystal"
      tag.save!

      Tag.all.size.should eq 0
      Tag.using(:other).get!(pk: tag.pk).name.should eq "crystal"
    end
  end

  describe "::transaction" do
    it "allows to wrap successful operations in a transaction" do
      TestUser.transaction do
        TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd@example.com", first_name: "Jil", last_name: "Dan")
      end
      TestUser.all.size.should eq 2
    end

    it "allows to wrap unsuccessful operations in a transaction" do
      expect_raises Exception, "Unexpected" do
        TestUser.transaction do
          TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
          raise "Unexpected error"
        end
      end
      TestUser.all.size.should eq 0
    end

    it "allows to wrap successful operations in a transaction using a specific DB alias" do
      TestUser.transaction(using: :other) do
        TestUser.using(:other).create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
        TestUser.using(:other).create!(username: "jd2", email: "jd@example.com", first_name: "Jil", last_name: "Dan")
      end
      TestUser.all.size.should eq 0
      TestUser.using(:other).all.size.should eq 2
    end

    it "allows to wrap unsuccessful operations in a transaction using a specific DB alias" do
      expect_raises Exception, "Unexpected" do
        TestUser.transaction(using: :other) do
          TestUser.using(:other).create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
          raise "Unexpected error"
        end
      end
      TestUser.all.size.should eq 0
      TestUser.using(:other).all.size.should eq 0
    end
  end

  describe "#transaction" do
    it "allows to wrap successful operations in a transaction" do
      user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")

      user.transaction do
        TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
        TestUser.create!(username: "jd2", email: "jd@example.com", first_name: "Jil", last_name: "Dan")
      end

      TestUser.all.size.should eq 3
    end

    it "allows to wrap unsuccessful operations in a transaction" do
      user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")

      expect_raises Exception, "Unexpected" do
        user.transaction do
          TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
          raise "Unexpected error"
        end
      end

      TestUser.all.size.should eq 1
    end

    it "allows to wrap successful operations in a transaction using a specific DB alias" do
      user = TestUser
        .using(:other)
        .create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")

      user.transaction(using: :other) do
        TestUser.using(:other).create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
        TestUser.using(:other).create!(username: "jd2", email: "jd@example.com", first_name: "Jil", last_name: "Dan")
      end
      TestUser.all.size.should eq 0
      TestUser.using(:other).all.size.should eq 3
    end

    it "allows to wrap unsuccessful operations in a transaction using a specific DB alias" do
      user = TestUser
        .using(:other)
        .create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")

      expect_raises Exception, "Unexpected" do
        user.transaction(using: :other) do
          TestUser.using(:other).create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
          raise "Unexpected error"
        end
      end
      TestUser.all.size.should eq 0
      TestUser.using(:other).all.size.should eq 1
    end

    it "uses the sticky database alias when no explicit alias is provided" do
      user = TestUser
        .using(:other)
        .create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")

      user.transaction do
        TestUser.using(:other).create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      end

      TestUser.all.size.should eq 0
      TestUser.using(:other).all.size.should eq 2
    end
  end
end

module Marten::DB::Model::ConnectionSpec
  class OtherDBRouter < Marten::DB::Router::Base
    def db_for_read(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "other"
    end

    def db_for_write(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "other"
    end
  end

  class PrimaryReplicaRouter < Marten::DB::Router::Base
    def db_for_read(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "other"
    end

    def db_for_write(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "default"
    end
  end
end
