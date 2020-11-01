require "./spec_helper"

describe Marten::Core::Validation do
  describe "#errors" do
    it "returns an ErrorSet object" do
      foo = Marten::Core::ValidationSpec::Foo.new
      foo.errors.should be_a(Marten::Core::Validation::ErrorSet)
    end

    it "is empty by default" do
      foo = Marten::Core::ValidationSpec::Foo.new
      foo.errors.should be_empty
    end

    it "contains the added errors if applicable" do
      foo = Marten::Core::ValidationSpec::Foo.new
      foo.errors.add("This is invalid!")

      foo.errors.size.should eq 1
      foo.errors.first.message.should eq "This is invalid!"
      foo.errors.first.type.should eq Marten::Core::Validation::ErrorSet::DEFAULT_ERROR_TYPE.to_s
      foo.errors.first.field.should be_nil
    end
  end

  describe "#valid?" do
    it "returns true if the object is valid" do
      foo = Marten::Core::ValidationSpec::Foo.new
      foo.bar = 10

      foo.valid?.should be_true
      foo.errors.should be_empty
    end

    it "returns true if the object is invalid" do
      foo = Marten::Core::ValidationSpec::Foo.new

      foo.valid?.should be_false

      foo.errors.size.should eq 1
      foo.errors.first.message.should eq "This is invalid!"
      foo.errors.first.type.should eq Marten::Core::Validation::ErrorSet::DEFAULT_ERROR_TYPE.to_s
      foo.errors.first.field.should eq "bar"
    end
  end

  describe "#invalid?" do
    it "returns false if the object is valid" do
      foo = Marten::Core::ValidationSpec::Foo.new
      foo.bar = 10

      foo.invalid?.should be_false
      foo.errors.should be_empty
    end

    it "returns true if the object is invalid" do
      foo = Marten::Core::ValidationSpec::Foo.new

      foo.invalid?.should be_true

      foo.errors.size.should eq 1
      foo.errors.first.message.should eq "This is invalid!"
      foo.errors.first.type.should eq Marten::Core::Validation::ErrorSet::DEFAULT_ERROR_TYPE.to_s
      foo.errors.first.field.should eq "bar"
    end
  end
end

module Marten::Core::ValidationSpec
  class Foo
    include Marten::Core::Validation

    @bar : Int32 = 0

    setter bar

    def validate
      errors.add(:bar, "This is invalid!") if @bar == 0
    end
  end
end
