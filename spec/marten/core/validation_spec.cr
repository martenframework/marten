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

    it "makes use of defined validation methods" do
      a = Marten::Core::ValidationSpec::A.new

      a.valid?.should be_false

      a.errors.size.should eq 1
      a.errors.first.message.should eq "The subject is blank!"
      a.errors.first.field.should eq "subject"

      a.subject = "Hello"

      a.valid?.should be_true

      a.errors.empty?.should be_true
    end

    it "makes use of the class defined validation methods and those of its ancestors" do
      b = Marten::Core::ValidationSpec::B.new

      b.valid?.should be_false

      b.errors.size.should eq 2
      b.errors.to_a[0].message.should eq "The subject is blank!"
      b.errors.to_a[0].field.should eq "subject"
      b.errors.to_a[1].message.should eq "The content is blank!"
      b.errors.to_a[1].field.should eq "content"

      b.subject = "Hello"
      b.content = "This is a message"

      b.valid?.should be_true

      b.errors.empty?.should be_true
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

  class A
    include Marten::Core::Validation

    @subject : String = ""

    setter subject

    validate :validate_subject

    private def validate_subject
      errors.add(:subject, "The subject is blank!") if @subject.empty?
    end
  end

  class B < A
    @content : String = ""

    setter content

    validate :validate_content

    private def validate_content
      errors.add(:content, "The content is blank!") if @content.empty?
    end
  end
end
