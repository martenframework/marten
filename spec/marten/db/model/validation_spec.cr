require "./spec_helper"
require "./validation_spec/app"

describe Marten::DB::Model::Validation do
  with_installed_apps Marten::DB::Model::ValidationSpec::App

  describe "#valid?" do
    it "validates all the underlying fields" do
      object_1 = Marten::DB::Model::ValidationSpec::Record.new(is_active: false)
      object_1.valid?.should be_false
      object_1.errors[0].field.should eq "name"
      object_1.errors[0].type.should eq "null"

      object_2 = Marten::DB::Model::ValidationSpec::Record.new(name: "", is_active: false)
      object_2.valid?.should be_false
      object_2.errors[0].field.should eq "name"
      object_2.errors[0].type.should eq "blank"
    end

    it "uses custom validation rules" do
      object = Marten::DB::Model::ValidationSpec::Record.new(name: "must_be_active", is_active: false)
      object.valid?.should be_false
      object.errors[0].message.should eq "The record must be active"
    end

    it "runs field validations consistently with validation callbacks" do
      object = Marten::DB::Model::ValidationSpec::Record.new(is_active: false)

      object.valid?.should be_false
      object.errors[0].field.should eq "name"
      object.errors[0].type.should eq "null"

      object.before_validation_errors_presence?.should eq false
    end
  end
end
