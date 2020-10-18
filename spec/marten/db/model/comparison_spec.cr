require "./spec_helper"

describe Marten::DB::Model::Comparison do
  describe "#==" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")
    end

    it "returns true if the two model instances are the same object for a persisted record" do
      user = TestUser.get!(username: "jd1")
      (user == user).should be_true
    end

    it "returns true if the two model instances are not persisted" do
      user = TestUser.new
      (user == user).should be_true
    end

    it "returns true if the two model instances are the same record at the DB level" do
      user1 = TestUser.get!(username: "jd1")
      user2 = TestUser.get!(username: "jd1")
      (user1 == user2).should be_true
    end

    it "returns false if the two model instances are not the same record at the DB level" do
      user1 = TestUser.get!(username: "jd1")
      user2 = TestUser.get!(username: "foo")
      (user1 == user2).should be_false
    end

    it "returns false if two non-persisted model instances are not the same object" do
      user1 = TestUser.new
      user2 = TestUser.new
      (user1 == user2).should be_false
    end
  end

  describe "#<=>" do
    before_each do
      TestUser.create!(username: "jd1", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "fb@example.com", first_name: "Foo", last_name: "Bar")
    end

    it "returns a positive number if the object is considered greater than the other one based on the primary key" do
      user1 = TestUser.get!(username: "jd1")
      user2 = TestUser.get!(username: "foo")
      (user2 <=> user1).should eq 1
    end

    it "returns a negative number if the object is considered lesser than the other one based on the primary key" do
      user1 = TestUser.get!(username: "jd1")
      user2 = TestUser.get!(username: "foo")
      (user1 <=> user2).should eq -1
    end

    it "returns 0 the objects have the same primary key" do
      user1 = TestUser.get!(username: "jd1")
      user2 = TestUser.get!(username: "jd1")
      (user1 <=> user2).should eq 0
      (user2 <=> user1).should eq 0
    end

    it "returns nil if one of the compared objects has no primary key" do
      user1 = TestUser.get!(username: "jd1")
      user2 = TestUser.new
      (user1 <=> user2).should be_nil
      (user2 <=> user1).should be_nil
    end
  end
end
