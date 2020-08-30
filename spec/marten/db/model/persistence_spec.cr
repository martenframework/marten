require "./spec_helper"

describe Marten::DB::Model::Persistence do
  around_each do |t|
    schema_editor = Marten::DB::Management::SchemaEditor.for(Marten::DB::Connection.default)
    schema_editor.create_model(TestUser)

    t.run

    schema_editor.delete_model(TestUser)
  end

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
  end
end
