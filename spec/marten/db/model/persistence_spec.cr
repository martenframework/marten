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

    it "runs after_create_commit callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create
      obj.after_create_commit_track.should eq "after_create_commit"
    end

    it "runs after_save_commit callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create
      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create
      obj.after_update_commit_track.should eq "unset"
      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_create_rollback callbacks as expected in case of a rollback" do
      obj = nil

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj = Marten::DB::Model::PersistenceSpec::Record.create
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_rollback_track.should eq "after_create_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback" do
      obj = nil

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj = Marten::DB::Model::PersistenceSpec::Record.create
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback" do
      obj = nil

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj = Marten::DB::Model::PersistenceSpec::Record.create
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "unset"
      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback" do
      obj = nil

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj = Marten::DB::Model::PersistenceSpec::Record.create
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
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

    it "runs after_create_commit callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.after_create_commit_track.should eq "after_create_commit"
    end

    it "runs after_save_commit callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.after_update_commit_track.should eq "unset"
      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_create_rollback callbacks as expected in case of a rollback" do
      obj = nil

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj = Marten::DB::Model::PersistenceSpec::Record.create!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_rollback_track.should eq "after_create_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback" do
      obj = nil

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj = Marten::DB::Model::PersistenceSpec::Record.create!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback" do
      obj = nil

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj = Marten::DB::Model::PersistenceSpec::Record.create!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "unset"
      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback" do
      obj = nil

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj = Marten::DB::Model::PersistenceSpec::Record.create!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
    end
  end

  describe "#save" do
    it "allows to save a new object" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.save.should be_true
      object.persisted?.should be_true
    end

    it "allows to save a new object by bypassing validations" do
      object = TestUser.new(username: "jd", email: "jd@example.com", last_name: "Doe", first_name: "")
      object.save(validate: false).should be_true
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

    it "allows to save an existing object by bypassing validations" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.first_name = ""
      object.save(validate: false).should be_true
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
        post.save
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

    it "properly handles new objects using non-integer IDs" do
      obj = TagWithUUID.new(label: "my_tag")
      obj.save
      obj.pk.should be_a(UUID)
      TagWithUUID.get!(pk: obj.pk).should eq obj
    end

    it "runs after_create_commit callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.save
      obj.after_create_commit_track.should eq "after_create_commit"
    end

    it "runs after_save_commit callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.save
      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.save
      obj.after_update_commit_track.should eq "unset"
      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_update_commit callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.name = "updated"

      obj.after_update_commit_track.should eq "unset"

      obj.save

      obj.after_update_commit_track.should eq "after_update_commit"
    end

    it "runs after_save_commit callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.name = "updated"

      obj.after_save_commit_track = "unset"
      obj.save

      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.name = "updated"
      obj.save

      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_create_rollback callbacks as expected in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.save
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_rollback_track.should eq "after_create_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.save
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.save
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "unset"
      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.save
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
    end

    it "runs after_update_rollback callbacks as expected in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.name = "updated"
        obj.save
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "after_update_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.name = "updated"
        obj.save
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.name = "updated"
        obj.save
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.after_create_commit_track = "unset"
      obj.after_save_commit_track = "unset"

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.name = "updated"
        obj.save
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
    end

    context "with multiple table inheritance" do
      it "allows to save new records and their parent records" do
        address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 1")
        student = Marten::DB::Model::PersistenceSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        check_student = ->(s : Marten::DB::Model::PersistenceSpec::Student) do
          s.persisted?.should be_true
          s.address!.persisted?.should be_true
          s.person_ptr!.persisted?.should be_true
          s.id.should_not be_nil
          s.pk.should_not be_nil
          s.person_ptr_id.should eq s.id
          s.name.should eq "Student 1"
          s.email.should eq "student-1@example.com"
          s.address.should eq address
          s.grade.should eq "10"
        end

        check_student.call(student)
        check_student.call(student.reload)
        check_student.call(Marten::DB::Model::PersistenceSpec::Student.get!(pk: student.pk))
      end

      it "allows to save new records and their parent records with multiple levels of inheritance" do
        address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 1")
        alt_student = Marten::DB::Model::PersistenceSpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )

        check_student = ->(s : Marten::DB::Model::PersistenceSpec::AltStudent) do
          s.persisted?.should be_true
          s.address!.persisted?.should be_true
          s.person_ptr!.persisted?.should be_true
          s.id.should_not be_nil
          s.pk.should_not be_nil
          s.person_ptr_id.should eq s.id
          s.name.should eq "Student 1"
          s.email.should eq "student-1@example.com"
          s.address.should eq address
          s.grade.should eq "10"
          s.alt_grade.should eq "11"
        end

        check_student.call(alt_student)
        check_student.call(alt_student.reload)
        check_student.call(Marten::DB::Model::PersistenceSpec::AltStudent.get!(pk: alt_student.pk))
      end

      it "allows to save new records and their parent records when they involve PKs without auto increment" do
        address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 1")
        restaurant = Marten::DB::Model::PersistenceSpec::Restaurant.create!(
          name: "Super restaurant",
          address: address,
          serves_hot_dogs: true,
          serves_pizza: false,
        )

        check_restaurant = ->(r : Marten::DB::Model::PersistenceSpec::Restaurant) do
          r.persisted?.should be_true
          r.address!.persisted?.should be_true
          r.place_ptr!.persisted?.should be_true
          r.id.should_not be_nil
          r.pk.should_not be_nil
          r.place_ptr_id.should eq ::UUID.new(r.id!).hexstring
          r.name.should eq "Super restaurant"
          r.address.should eq address
          r.serves_hot_dogs.should be_true
          r.serves_pizza.should be_false
        end

        check_restaurant.call(restaurant)
        check_restaurant.call(restaurant.reload)
        check_restaurant.call(Marten::DB::Model::PersistenceSpec::Restaurant.get!(pk: restaurant.pk))
      end

      it "allows to update records and their parent records" do
        old_address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 1")
        new_address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 2")

        student = Marten::DB::Model::PersistenceSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: old_address,
          grade: "10"
        )

        student = Marten::DB::Model::PersistenceSpec::Student.get!(pk: student.pk)
        student.name = "Student 2"
        student.email = "student-2@example.com"
        student.address = new_address
        student.grade = "11"
        student.save

        check_student = ->(s : Marten::DB::Model::PersistenceSpec::Student) do
          s.persisted?.should be_true
          s.address!.persisted?.should be_true
          s.person_ptr!.persisted?.should be_true
          s.id.should_not be_nil
          s.pk.should_not be_nil
          s.person_ptr_id.should eq s.id
          s.name.should eq "Student 2"
          s.email.should eq "student-2@example.com"
          s.address.should eq new_address
          s.grade.should eq "11"
        end

        check_student.call(student)
        check_student.call(student.reload)
        check_student.call(Marten::DB::Model::PersistenceSpec::Student.get!(pk: student.pk))
      end

      it "allows to update records and their parent records with multiple levels of inheritance" do
        old_address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 1")
        new_address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 2")

        alt_student = Marten::DB::Model::PersistenceSpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: old_address,
          grade: "10",
          alt_grade: "11"
        )

        alt_student = Marten::DB::Model::PersistenceSpec::AltStudent.get!(pk: alt_student.pk)
        alt_student.name = "Student 2"
        alt_student.email = "student-2@example.com"
        alt_student.address = new_address
        alt_student.grade = "11"
        alt_student.alt_grade = "12"
        alt_student.save

        check_student = ->(s : Marten::DB::Model::PersistenceSpec::AltStudent) do
          s.persisted?.should be_true
          s.address!.persisted?.should be_true
          s.person_ptr!.persisted?.should be_true
          s.id.should_not be_nil
          s.pk.should_not be_nil
          s.person_ptr_id.should eq s.id
          s.name.should eq "Student 2"
          s.email.should eq "student-2@example.com"
          s.address.should eq new_address
          s.grade.should eq "11"
          s.alt_grade.should eq "12"
        end

        check_student.call(alt_student)
        check_student.call(alt_student.reload)
        check_student.call(Marten::DB::Model::PersistenceSpec::AltStudent.get!(pk: alt_student.pk))
      end

      it "allows to update records and their parent records when they involve PKs without auto increment" do
        old_address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 1")
        new_address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 2")

        restaurant = Marten::DB::Model::PersistenceSpec::Restaurant.create!(
          name: "Super restaurant",
          address: old_address,
          serves_hot_dogs: true,
          serves_pizza: false,
        )

        restaurant = Marten::DB::Model::PersistenceSpec::Restaurant.get!(pk: restaurant.pk)
        restaurant.name = "Super restaurant 2"
        restaurant.address = new_address
        restaurant.serves_hot_dogs = false
        restaurant.serves_pizza = true
        restaurant.save

        check_restaurant = ->(r : Marten::DB::Model::PersistenceSpec::Restaurant) do
          r.persisted?.should be_true
          r.address!.persisted?.should be_true
          r.place_ptr!.persisted?.should be_true
          r.id.should_not be_nil
          r.pk.should_not be_nil
          r.place_ptr_id.should eq ::UUID.new(r.id!).hexstring
          r.name.should eq "Super restaurant 2"
          r.address.should eq new_address
          r.serves_hot_dogs.should be_false
          r.serves_pizza.should be_true
        end

        check_restaurant.call(restaurant)
        check_restaurant.call(restaurant.reload)
        check_restaurant.call(Marten::DB::Model::PersistenceSpec::Restaurant.get!(pk: restaurant.pk))
      end

      it "validates records and their parent records as expected" do
        student = Marten::DB::Model::PersistenceSpec::Student.new

        student.valid?.should be_false
        student.errors.size.should eq 4
        student.errors[0].field.should eq "name"
        student.errors[0].type.should eq "null"
        student.errors[1].field.should eq "email"
        student.errors[1].type.should eq "null"
        student.errors[2].field.should eq "address_id"
        student.errors[2].type.should eq "null"
        student.errors[3].field.should eq "grade"
        student.errors[3].type.should eq "null"
      end

      it "validates records and their parent records as expected with multiple levels of inheritance" do
        student = Marten::DB::Model::PersistenceSpec::AltStudent.new

        student.valid?.should be_false
        student.errors.size.should eq 5
        student.errors[0].field.should eq "grade"
        student.errors[0].type.should eq "null"
        student.errors[1].field.should eq "name"
        student.errors[1].type.should eq "null"
        student.errors[2].field.should eq "email"
        student.errors[2].type.should eq "null"
        student.errors[3].field.should eq "address_id"
        student.errors[3].type.should eq "null"
        student.errors[4].field.should eq "alt_grade"
        student.errors[4].type.should eq "null"
      end
    end
  end

  describe "#save!" do
    it "allows to save a new object" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.save!.should be_true
      object.persisted?.should be_true
    end

    it "allows to save a new object by bypassing validations" do
      object = TestUser.new(username: "jd", email: "jd@example.com", last_name: "Doe", first_name: "")
      object.save!(validate: false).should be_true
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

    it "allows to save an existing object by bypassing validations" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.first_name = ""
      object.save!(validate: false).should be_true
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

    it "runs after_create_commit callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.save!
      obj.after_create_commit_track.should eq "after_create_commit"
    end

    it "runs after_save_commit callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.save!
      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.save!
      obj.after_update_commit_track.should eq "unset"
      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_update_commit callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.name = "updated"

      obj.after_update_commit_track.should eq "unset"

      obj.save!

      obj.after_update_commit_track.should eq "after_update_commit"
    end

    it "runs after_save_commit callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.name = "updated"

      obj.after_save_commit_track = "unset"
      obj.save!

      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.name = "updated"
      obj.save!

      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_create_rollback callbacks as expected in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.save!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_rollback_track.should eq "after_create_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.save!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.save!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "unset"
      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.save!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
    end

    it "runs after_update_rollback callbacks as expected in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.name = "updated"
        obj.save!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "after_update_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.name = "updated"
        obj.save!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.name = "updated"
        obj.save!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.after_create_commit_track = "unset"
      obj.after_save_commit_track = "unset"

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.name = "updated"
        obj.save!
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
    end
  end

  describe "#update" do
    it "allows to save a new object" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update(username: "test1", email: "test1@example.com").should be_true

      object.persisted?.should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "allows to save a new object with attributes expressed as a hash" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update({"username" => "test1", "email" => "test1@example.com"}).should be_true

      object.persisted?.should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "allows to save a new object with attributes expressed as a named tuple" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update({username: "test1", email: "test1@example.com"}).should be_true

      object.persisted?.should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "returns false if the new object is invalid" do
      object = TestUser.new(last_name: "Doe")
      object.update(username: nil).should be_false
      object.persisted?.should be_false
    end

    it "allows to update an existing object" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update(username: "test1", email: "test1@example.com").should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "allows to update an existing object with attributes expressed as a hash" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update({"username" => "test1", "email" => "test1@example.com"}).should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "allows to update an existing object with attributes expressed as a named tuple" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update({username: "test1", email: "test1@example.com"}).should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "returns false if an existing object is invalid" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update(username: nil).should be_false
      object.reload.username.should eq "jd"
    end

    it "raises if an optional related object is not persisted" do
      existing_user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      new_user = TestUser.new

      post = Post.new(author: existing_user, updated_by: new_user, title: "Test")

      expect_raises(
        Marten::DB::Errors::UnmetSaveCondition,
        "Save is prohibited because related object 'updated_by' is not persisted"
      ) do
        post.update(title: "Updated")
      end
    end

    it "runs before_create and after_create callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.before_create_track.should eq "unset"
      obj.after_create_track.should eq "unset"

      obj.update(name: "updated")

      obj.before_create_track.should eq "before_create"
      obj.after_create_track.should eq "after_create"
    end

    it "runs before_save and after_save callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.before_save_track.should eq "unset"
      obj.after_save_track.should eq "unset"

      obj.update(name: "updated")

      obj.before_save_track.should eq "before_save"
      obj.after_save_track.should eq "after_save"
    end

    it "runs before_update and after_update callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"

      obj.update(name: "updated")

      obj.before_update_track.should eq "before_update"
      obj.after_update_track.should eq "after_update"
    end

    it "does not run before_update and after_update callbacks for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.update(name: "updated")

      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"
    end

    it "runs after_create_commit callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.update(name: "updated")
      obj.after_create_commit_track.should eq "after_create_commit"
    end

    it "runs after_save_commit callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.update(name: "updated")
      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.update(name: "updated")
      obj.after_update_commit_track.should eq "unset"
      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_update_commit callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      obj.after_update_commit_track.should eq "unset"

      obj.update(name: "updated")

      obj.after_update_commit_track.should eq "after_update_commit"
    end

    it "runs after_save_commit callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      obj.after_save_commit_track = "unset"
      obj.update(name: "updated")

      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.update(name: "updated")

      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_create_rollback callbacks as expected in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_rollback_track.should eq "after_create_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "unset"
      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
    end

    it "runs after_update_rollback callbacks as expected in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "after_update_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.after_create_commit_track = "unset"
      obj.after_save_commit_track = "unset"

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
    end
  end

  describe "#update!" do
    it "allows to save a new object" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update!(username: "test1", email: "test1@example.com").should be_true

      object.persisted?.should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "allows to save a new object with attributes expressed as a hash" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update!({"username" => "test1", "email" => "test1@example.com"}).should be_true

      object.persisted?.should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "allows to save a new object with attributes expressed as a named tuple" do
      object = TestUser.new(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update!({username: "test1", email: "test1@example.com"}).should be_true

      object.persisted?.should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "raises if the new object is invalid" do
      object = TestUser.new(last_name: "Doe")
      expect_raises(Marten::DB::Errors::InvalidRecord) { object.update!(username: nil) }
      object.persisted?.should be_false
    end

    it "allows to update an existing object" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update!(username: "test1", email: "test1@example.com").should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "allows to update an existing object with attributes expressed as a hash" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update!({"username" => "test1", "email" => "test1@example.com"}).should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "allows to update an existing object with attributes expressed as a named tuple" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      object.update!({username: "test1", email: "test1@example.com"}).should be_true

      object.reload
      object.username.should eq "test1"
      object.email.should eq "test1@example.com"
    end

    it "raises if an existing object is invalid" do
      object = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      expect_raises(Marten::DB::Errors::InvalidRecord) { object.update!(username: nil) }
      object.reload.username.should eq "jd"
    end

    it "raises if an optional related object is not persisted" do
      existing_user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      new_user = TestUser.new

      post = Post.new(author: existing_user, updated_by: new_user, title: "Test")

      expect_raises(
        Marten::DB::Errors::UnmetSaveCondition,
        "Save is prohibited because related object 'updated_by' is not persisted"
      ) do
        post.update!(title: "Updated")
      end
    end

    it "runs before_create and after_create callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.before_create_track.should eq "unset"
      obj.after_create_track.should eq "unset"

      obj.update!(name: "updated")

      obj.before_create_track.should eq "before_create"
      obj.after_create_track.should eq "after_create"
    end

    it "runs before_save and after_save callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.before_save_track.should eq "unset"
      obj.after_save_track.should eq "unset"

      obj.update!(name: "updated")

      obj.before_save_track.should eq "before_save"
      obj.after_save_track.should eq "after_save"
    end

    it "runs before_update and after_update callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"

      obj.update!(name: "updated")

      obj.before_update_track.should eq "before_update"
      obj.after_update_track.should eq "after_update"
    end

    it "does not run before_update and after_update callbacks for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.update!(name: "updated")

      obj.before_update_track.should eq "unset"
      obj.after_update_track.should eq "unset"
    end

    it "runs after_create_commit callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.update!(name: "updated")
      obj.after_create_commit_track.should eq "after_create_commit"
    end

    it "runs after_save_commit callbacks as expected for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.update!(name: "updated")
      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new
      obj.update!(name: "updated")
      obj.after_update_commit_track.should eq "unset"
      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_update_commit callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      obj.after_update_commit_track.should eq "unset"

      obj.update!(name: "updated")

      obj.after_update_commit_track.should eq "after_update_commit"
    end

    it "runs after_save_commit callbacks as expected for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      obj.after_save_commit_track = "unset"
      obj.update!(name: "updated")

      obj.after_save_commit_track.should eq "after_save_commit"
    end

    it "does not run other after_commit callbacks for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.update!(name: "updated")

      obj.after_delete_commit_track.should eq "unset"
    end

    it "runs after_create_rollback callbacks as expected in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update!(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_rollback_track.should eq "after_create_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update!(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update!(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "unset"
      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback for new records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update!(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
    end

    it "runs after_update_rollback callbacks as expected in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update!(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_update_rollback_track.should eq "after_update_rollback"
    end

    it "runs after_save_rollback callbacks as expected in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update!(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_save_rollback_track.should eq "after_save_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update!(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_delete_rollback_track.should eq "unset"
    end

    it "does not run other after_commit callbacks in case of a rollback for existing records" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.after_create_commit_track = "unset"
      obj.after_save_commit_track = "unset"

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.update!(name: "updated")
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_commit_track.should eq "unset"
      obj.not_nil!.after_update_commit_track.should eq "unset"
      obj.not_nil!.after_save_commit_track.should eq "unset"
      obj.not_nil!.after_delete_commit_track.should eq "unset"
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

    it "runs before_delete and after_delete in a transaction" do
      obj = Marten::DB::Model::PersistenceSpec::UndeletableRecord.create!

      expect_raises(Exception, "Deletion prevented!") do
        obj.delete
      end

      Marten::DB::Model::PersistenceSpec::UndeletableRecord.filter(id: obj.id).exists?.should be_true
    end

    it "runs after_delete_commit callbacks as expected" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!
      obj.delete
      obj.after_delete_commit_track.should eq "after_delete_commit"
    end

    it "does not run other after_commit callbacks" do
      obj = Marten::DB::Model::PersistenceSpec::Record.new

      obj.after_create_commit_track.should eq "unset"
      obj.after_update_commit_track.should eq "unset"
      obj.after_save_commit_track.should eq "unset"

      obj.delete

      obj.after_create_commit_track.should eq "unset"
      obj.after_update_commit_track.should eq "unset"
      obj.after_save_commit_track.should eq "unset"
    end

    it "runs after_delete_rollback callbacks as expected in case of a rollback" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.delete
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_delete_rollback_track.should eq "after_delete_rollback"
    end

    it "does not run other after_rollback callbacks in case of a rollback" do
      obj = Marten::DB::Model::PersistenceSpec::Record.create!

      Marten::DB::Model::PersistenceSpec::Record.transaction do
        obj.delete
        raise Marten::DB::Errors::Rollback.new("Rollback!")
      end

      obj.not_nil!.after_create_rollback_track.should eq "unset"
      obj.not_nil!.after_update_rollback_track.should eq "unset"
      obj.not_nil!.after_save_rollback_track.should eq "unset"
    end

    context "with multiple table inheritance" do
      it "deletes the object and its parents as expected" do
        address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 2")

        student = Marten::DB::Model::PersistenceSpec::Student.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10"
        )

        student.delete

        Marten::DB::Model::PersistenceSpec::Student.get(name: "Student 1").should be_nil
        Marten::DB::Model::PersistenceSpec::Person.get(name: "Student 1").should be_nil
      end

      it "deletes the object and its parents as expected with multiple levels of inheritance" do
        address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 2")

        student = Marten::DB::Model::PersistenceSpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )

        student.delete

        Marten::DB::Model::PersistenceSpec::AltStudent.get(name: "Student 1").should be_nil
        Marten::DB::Model::PersistenceSpec::Student.get(name: "Student 1").should be_nil
        Marten::DB::Model::PersistenceSpec::Person.get(name: "Student 1").should be_nil
      end
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

    it "resets direct relations as expected" do
      user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      post = Post.create(author: user, title: "Test")

      TestUser.all.update(username: "updated")

      post.reload
      post.author!.username.should eq "updated"
    end

    it "resets reverse relations as expected" do
      user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      TestUserProfile.create!(user: user, bio: "Test")

      user.profile!.bio.should eq "Test"

      TestUserProfile.all.update(bio: "Updated")

      user.reload

      user.profile!.bio.should eq "Updated"
    end

    it "resets reverse many-to-one query sets as expected" do
      user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      post_1 = Post.create!(title: "Test 1", author: user)
      post_2 = Post.create!(title: "Test 2", author: user)

      user.posts.map(&.title).to_set.should eq(Set{"Test 1", "Test 2"})

      Post.filter(id: post_1.id).update(title: "Test 1 - Updated")
      Post.filter(id: post_2.id).update(title: "Test 2 - Updated")

      user.posts.map(&.title).to_set.should eq(Set{"Test 1", "Test 2"})

      user.reload

      user.posts.map(&.title).to_set.should eq(Set{"Test 1 - Updated", "Test 2 - Updated"})
    end

    it "resets many-to-many query sets as expected" do
      tag_1 = Tag.create!(name: "Tag 1", is_active: true)
      tag_2 = Tag.create!(name: "Tag 2", is_active: true)

      user = TestUser.create!(username: "jd", email: "jd@example.com", first_name: "John", last_name: "Doe")
      user.tags.add(tag_1)
      user.tags.add(tag_2)

      user.tags.map(&.name).to_set.should eq(Set{"Tag 1", "Tag 2"})

      Tag.filter(id: tag_1.id).update(name: "Tag 1 - Updated")

      user.tags.map(&.name).to_set.should eq(Set{"Tag 1", "Tag 2"})

      user.reload

      user.tags.map(&.name).to_set.should eq(Set{"Tag 1 - Updated", "Tag 2"})
    end

    it "resets reverse many-to-many query sets as expected" do
      tag = Tag.create!(name: "Tag 1", is_active: true)

      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_1.tags.add(tag)

      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_2.tags.add(tag)

      tag.test_users.map(&.username).to_set.should eq(Set{"jd1", "jd2"})

      TestUser.filter(id: user_1.id).update(username: "jd1updated")

      tag.test_users.map(&.username).to_set.should eq(Set{"jd1", "jd2"})

      tag.reload

      tag.test_users.map(&.username).to_set.should eq(Set{"jd1updated", "jd2"})
    end

    context "with multi table inheritance" do
      it "reloads parent objects as well" do
        address = Marten::DB::Model::PersistenceSpec::Address.create!(street: "Street 1")
        alt_student = Marten::DB::Model::PersistenceSpec::AltStudent.create!(
          name: "Student 1",
          email: "student-1@example.com",
          address: address,
          grade: "10",
          alt_grade: "11"
        )

        Marten::DB::Model::PersistenceSpec::Person.all.update(name: "Updated")
        Marten::DB::Model::PersistenceSpec::Student.all.update(grade: "10-updated")
        Marten::DB::Model::PersistenceSpec::AltStudent.all.update(alt_grade: "11-updated")

        alt_student.reload

        alt_student.name.should eq "Updated"
        alt_student.grade.should eq "10-updated"
        alt_student.alt_grade.should eq "11-updated"
      end
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
