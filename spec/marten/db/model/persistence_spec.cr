require "./spec_helper"

describe Marten::DB::Model::Persistence do
  describe "::create" do
    it "returns the non-persisted model instance if it is invalid" do
      object = TestUser.create(username: nil)
      object.valid?.should be_false
      object.persisted?.should be_false
    end

    it "returns the persisted model instance if it is valid" do
      object = TestUser.create(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.valid?.should be_true
      object.persisted?.should be_true
    end

    it "allows to initialize the new invalid object in a dedicated block" do
      object = TestUser.create(username: nil) do |o|
        o.first_name = "John"
      end
      object.first_name.should eq "John"
      object.valid?.should be_false
      object.persisted?.should be_false
    end

    it "allows to initialize the new valid object in a dedicated block" do
      object = TestUser.create(username: "jd") do |o|
        o.email = "jd@example.com"
        o.first_name = "John"
        o.last_name = "Doe"
      end
      object.email.should eq "jd@example.com"
      object.first_name.should eq "John"
      object.last_name.should eq "Doe"
      object.valid?.should be_true
      object.persisted?.should be_true
    end

    it "raises if an optional related object is not persisted" do
      existing_user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      new_user = TestUser.new
      expect_raises(
        Marten::DB::Errors::UnmetSaveCondition,
        "Save is prohibited because related object 'updated_by' is not persisted"
      ) do
        Post.create(author: existing_user, updated_by: new_user, title: "Test")
      end
    end
  end

  describe "::create!" do
    it "raises InvalidRecord if the model instance is invalid" do
      expect_raises(Marten::DB::Errors::InvalidRecord) { TestUser.create!(username: nil) }
    end

    it "returns the persisted model instance if it is valid" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.valid?.should be_true
      object.persisted?.should be_true
    end

    it "allows to initialize the new valid object in a dedicated block" do
      object = TestUser.create!(username: "jd") do |o|
        o.email = "jd@example.com"
        o.first_name = "John"
        o.last_name = "Doe"
      end
      object.email.should eq "jd@example.com"
      object.first_name.should eq "John"
      object.last_name.should eq "Doe"
      object.valid?.should be_true
      object.persisted?.should be_true
    end
  end

  describe "#save" do
    it "allows to save a new object" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.save.should be_true
      object.persisted?.should be_true
    end

    it "returns false if the new object is invalid" do
      object = TestUser.new(last_name: "Doe")
      object.save.should be_false
      object.persisted?.should be_false
    end

    it "allows to save an existing object" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.username = "jd2"
      object.save.should be_true
    end

    it "returns false if an existing object is invalid" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.email = nil
      object.save.should be_false
    end

    it "raises if an optional related object is not persisted" do
      existing_user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      new_user = TestUser.new

      post = Post.new(author: existing_user, updated_by: new_user, title: "Test")

      expect_raises(
        Marten::DB::Errors::UnmetSaveCondition,
        "Save is prohibited because related object 'updated_by' is not persisted"
      ) do
        post.save!
      end
    end
  end

  describe "#save!" do
    it "allows to save a new object" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.save!.should be_true
      object.persisted?.should be_true
    end

    it "raises if the new object is invalid" do
      object = TestUser.new(last_name: "Doe")
      expect_raises(Marten::DB::Errors::InvalidRecord) { object.save! }
      object.persisted?.should be_false
    end

    it "allows to save an existing object" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.username = "jd2"
      object.save!.should be_true
    end

    it "raises if an existing object is invalid" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.email = nil
      expect_raises(Marten::DB::Errors::InvalidRecord) { object.save! }
    end
  end

  describe "#reload" do
    it "allows to reload an object" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")

      object_alt = TestUser.get!(pk: object.pk)
      object_alt.username = "jd2"
      object_alt.save!

      object.reload.username.should eq "jd2"
    end

    it "allows to reload an object from a new object whose primary key is manually assigned" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")

      object_alt = TestUser.new
      object_alt.pk = object.pk

      object.reload.username.should eq "jd"
      object.new_record?.should be_false
    end
  end

  describe "#new_record?" do
    it "returns true if the record does not exist in the database yet" do
      object = TestUser.new(username: "foobar")
      object.new_record?.should be_true
    end

    it "returns false for an existing record" do
      TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object = TestUser.get!(username: "jd")
      object.new_record?.should be_false
    end
  end
end
