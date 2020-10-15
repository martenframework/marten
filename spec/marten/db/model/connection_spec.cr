require "./spec_helper"

describe Marten::DB::Model::Connection do
  describe "::connection" do
    it "returns the default connection to use for the considered model" do
      TestUser.connection.should eq Marten::DB::Connection.default
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
          TestUser.create!(username: "jd2", email: "jd@example.com", first_name: "Jil", last_name: "Dan")
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
          TestUser.using(:other).create!(username: "jd2", email: "jd@example.com", first_name: "Jil", last_name: "Dan")
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
          TestUser.create!(username: "jd2", email: "jd@example.com", first_name: "Jil", last_name: "Dan")
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
          TestUser.using(:other).create!(username: "jd2", email: "jd@example.com", first_name: "Jil", last_name: "Dan")
        end
      end
      TestUser.all.size.should eq 0
      TestUser.using(:other).all.size.should eq 1
    end
  end
end
