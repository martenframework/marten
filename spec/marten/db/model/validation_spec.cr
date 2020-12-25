require "./spec_helper"

describe Marten::DB::Model::Validation do
  describe "#valid?" do
    it "validates all the underlying fields" do
      tag_1 = Tag.new(is_active: false)
      tag_1.valid?.should be_false
      tag_1.errors[0].field.should eq "name"
      tag_1.errors[0].type.should eq "null"

      tag_2 = Tag.new(name: "", is_active: false)
      tag_2.valid?.should be_false
      tag_2.errors[0].field.should eq "name"
      tag_2.errors[0].type.should eq "blank"
    end

    it "uses custom validation rules" do
      tag = Tag.new(name: "must_be_active", is_active: false)
      tag.valid?.should be_false
      tag.errors[0].message.should eq "The tag must be active"
    end
  end
end
