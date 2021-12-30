require "./spec_helper"

describe Marten::Core::Validation do
  describe "::validate" do
    it "can register multiple validation methods" do
      c = Marten::Core::ValidationSpec::C.new

      c.valid?.should be_false
      c.errors[0].message.should eq "The content is nil!"
      c.errors[0].field.should eq "content"

      c.content = ""
      c.valid?.should be_false
      c.errors[0].message.should eq "The content is blank!"
      c.errors[0].field.should eq "content"
    end
  end

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
      b.errors[0].message.should eq "The subject is blank!"
      b.errors[0].field.should eq "subject"
      b.errors[1].message.should eq "The content is blank!"
      b.errors[1].field.should eq "content"

      b.subject = "Hello"
      b.content = "This is a message"

      b.valid?.should be_true

      b.errors.empty?.should be_true
    end

    it "can run validations with an optional context expressed as a string" do
      obj = Marten::Core::ValidationSpec::ObjectWithContextualValidation.new
      obj.content = "bad"

      obj.valid?.should be_true
      obj.valid?("expected_context").should be_false

      obj.errors.size.should eq 1
      obj.errors[0].message.should eq "The content is bad!"
      obj.errors[0].field.should eq "content"
    end

    it "can run validations with an optional context expressed as a symbol" do
      obj = Marten::Core::ValidationSpec::ObjectWithContextualValidation.new
      obj.content = "bad"

      obj.valid?.should be_true
      obj.valid?(:expected_context).should be_false

      obj.errors.size.should eq 1
      obj.errors[0].message.should eq "The content is bad!"
      obj.errors[0].field.should eq "content"
    end

    it "runs before_validation and after_validation callbacks as expected" do
      obj = Marten::Core::ValidationSpec::ObjectWithCallbacks.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.valid?

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
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

    it "can run validations with an optional context expressed as a string" do
      obj = Marten::Core::ValidationSpec::ObjectWithContextualValidation.new
      obj.content = "bad"

      obj.invalid?.should be_false
      obj.invalid?("expected_context").should be_true

      obj.errors.size.should eq 1
      obj.errors[0].message.should eq "The content is bad!"
      obj.errors[0].field.should eq "content"
    end

    it "can run validations with an optional context expressed as a symbol" do
      obj = Marten::Core::ValidationSpec::ObjectWithContextualValidation.new
      obj.content = "bad"

      obj.invalid?.should be_false
      obj.invalid?(:expected_context).should be_true

      obj.errors.size.should eq 1
      obj.errors[0].message.should eq "The content is bad!"
      obj.errors[0].field.should eq "content"
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

  class C
    include Marten::Core::Validation

    @content : String? = nil

    setter content

    validate :validate_content_is_not_nil, :validate_content_is_not_blank

    private def validate_content_is_not_nil
      errors.add(:content, "The content is nil!") if @content.nil?
    end

    private def validate_content_is_not_blank
      errors.add(:content, "The content is blank!") if @content.try(&.empty?)
    end
  end

  class ObjectWithContextualValidation
    include Marten::Core::Validation

    @content : String? = nil

    setter content

    validate :validate_content_is_not_bad

    private def validate_content_is_not_bad
      return unless validation_context == "expected_context"
      errors.add(:content, "The content is bad!") if @content == "bad"
    end
  end

  class ObjectWithCallbacks
    include Marten::Core::Validation

    property foo : String? = nil
    property bar : String? = nil

    before_validation :set_foo
    after_validation :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end
end
