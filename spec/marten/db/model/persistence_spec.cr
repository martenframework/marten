require "./spec_helper"
require "./persistence_spec/app"

describe Marten::DB::Model::Persistence do
  with_installed_apps Marten::DB::Model::PersistenceSpec::App

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

    it "runs before_create and after_create callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create
      obj.before_create_track.should eq "before_create"
      obj.after_create_track.should eq "after_create"
    end

    it "runs before_save and after_save callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create
      obj.before_save_track.should eq "before_save"
      obj.after_save_track.should eq "after_save"
    end

    it "does not run before_update and after_update callbacks" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create
      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"
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

    it "runs before_create and after_create callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.before_create_track.should eq "before_create"
      obj.after_create_track.should eq "after_create"
    end

    it "runs before_save and after_save callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.before_save_track.should eq "before_save"
      obj.after_save_track.should eq "after_save"
    end

    it "does not run before_update and after_update callbacks" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"
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

    it "runs before_create and after_create callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.before_create_track.should eq "unset"
      obj.after_create_track.should eq "unset"

      obj.save

      obj.before_create_track.should eq "before_create"
      obj.after_create_track.should eq "after_create"
    end

    it "runs before_save and after_save callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.before_save_track.should eq "unset"
      obj.after_save_track.should eq "unset"

      obj.save

      obj.before_save_track.should eq "before_save"
      obj.after_save_track.should eq "after_save"
    end

    it "runs before_update and after_update callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"

      obj.name = "updated"
      obj.save

      obj.before_update_track.should eq "before_update"
      obj.after_update_track.should eq "after_update"
    end

    it "does not run before_update and after_update callbacks for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.save

      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"
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

    it "runs before_create and after_create callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.before_create_track.should eq "unset"
      obj.after_create_track.should eq "unset"

      obj.save!

      obj.before_create_track.should eq "before_create"
      obj.after_create_track.should eq "after_create"
    end

    it "runs before_save and after_save callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.before_save_track.should eq "unset"
      obj.after_save_track.should eq "unset"

      obj.save!

      obj.before_save_track.should eq "before_save"
      obj.after_save_track.should eq "after_save"
    end

    it "runs before_update and after_update callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"

      obj.name = "updated"
      obj.save!

      obj.before_update_track.should eq "before_update"
      obj.after_update_track.should eq "after_update"
    end

    it "does not run before_update and after_update callbacks for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.save!

      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"
    end
  end

  describe "#delete" do
    it "allows to delete objects" do
      obj_1 = Tag.create!(name: "crystal", is_active: true)
      obj_1.delete.should eq 1
      obj_1.deleted?.should be_true
      Tag.get(name: "crystal").should be_nil

      obj_2 = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      sub_obj_2 = Post.create!(title: "Test", author: obj_2)
      obj_2.delete.should eq 2
      obj_2.deleted?.should be_true
      TestUser.get(username: "jd").should be_nil
      Post.get(id: sub_obj_2.id).should be_nil
    end

    it "runs before_delete and after_delete callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      obj.before_delete_track.should be_nil
      obj.after_delete_track.should be_nil

      obj.delete

      obj.before_delete_track.should eq "before_delete"
      obj.after_delete_track.should eq "after_delete"
    end
  end

  describe "#deleted?" do
    it "returns true when an object is deleted" do
      obj = Tag.create!(name: "crystal", is_active: true)
      obj.delete
      obj.deleted?.should be_true
    end

    it "returns false when an object is not deleted" do
      obj = Tag.create!(name: "crystal", is_active: true)
      obj.deleted?.should be_false
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
