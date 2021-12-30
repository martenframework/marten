require "./spec_helper"

describe Marten::Core::Validation::Callbacks do
  describe "::before_validation" do
    it "allows to register a single before_validation callback" do
      obj = Marten::Core::Validation::CallbacksSpec::SingleBeforeValidationCallback.new

      obj.foo.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple before_validation callbacks through a single call" do
      obj = Marten::Core::Validation::CallbacksSpec::MultipleBeforeValidationCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple before_validation callbacks through multiple calls" do
      obj = Marten::Core::Validation::CallbacksSpec::MultipleBeforeValidationCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_validation" do
    it "allows to register a single after_validation callback" do
      obj = Marten::Core::Validation::CallbacksSpec::SingleAfterValidationCallback.new

      obj.foo.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_validation callbacks through a single call" do
      obj = Marten::Core::Validation::CallbacksSpec::MultipleAfterValidationCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_validation callbacks through multiple calls" do
      obj = Marten::Core::Validation::CallbacksSpec::MultipleAfterValidationCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "#run_before_validation_callbacks" do
    it "runs the before_validation callbacks in the order they were registered" do
      obj = Marten::Core::Validation::CallbacksSpec::Parent.new

      obj.shared_before.should be_nil

      obj.run_callbacks

      obj.shared_before.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::Core::Validation::CallbacksSpec::Child.new

      obj.shared_before.should be_nil
      obj.foo_before.should be_nil
      obj.abc_before.should be_nil

      obj.run_callbacks

      obj.shared_before.should eq "three"
      obj.foo_before.should eq "set_foo"
      obj.abc_before.should eq "set_abc"
    end
  end

  describe "#run_after_validation_callbacks" do
    it "runs the after_validation callbacks in the order they were registered" do
      obj = Marten::Core::Validation::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::Core::Validation::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end
end

module Marten::Core::Validation::CallbacksSpec
  class Base
    include Marten::Core::Validation::Callbacks

    def run_callbacks
      run_before_validation_callbacks
      run_after_validation_callbacks
    end
  end

  class SingleBeforeValidationCallback < Base
    property foo : String? = nil

    before_validation :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleBeforeValidationCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    before_validation :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleBeforeValidationCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    before_validation :set_foo
    before_validation "set_bar"

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class SingleAfterValidationCallback < Base
    property foo : String? = nil

    after_validation :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleAfterValidationCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    after_validation :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleAfterValidationCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    after_validation :set_foo
    after_validation :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class Parent < Base
    property foo_before : String? = nil
    property shared_before : String? = nil

    property foo_after : String? = nil
    property shared_after : String? = nil

    before_validation :set_one_before
    before_validation :set_two_before
    before_validation :set_foo_before

    after_validation :set_one_after
    after_validation :set_two_after
    after_validation :set_foo_after

    private def set_one_before
      self.shared_before = "one"
    end

    private def set_two_before
      self.shared_before = "two"
    end

    private def set_foo_before
      self.foo_before = "set_foo"
    end

    private def set_one_after
      self.shared_after = "one"
    end

    private def set_two_after
      self.shared_after = "two"
    end

    private def set_foo_after
      self.foo_after = "set_foo"
    end
  end

  class Child < Parent
    property abc_before : String? = nil

    property abc_after : String? = nil

    before_validation :set_three_before
    before_validation :set_abc_before

    after_validation :set_three_after
    after_validation :set_abc_after

    private def set_three_before
      self.shared_before = "three"
    end

    private def set_abc_before
      self.abc_before = "set_abc"
    end

    private def set_three_after
      self.shared_after = "three"
    end

    private def set_abc_after
      self.abc_after = "set_abc"
    end
  end
end
